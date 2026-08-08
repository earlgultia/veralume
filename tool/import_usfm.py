"""Convert licensed USFM packages into Veralume's normalized JSON input format."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path


BOOK_CODES = [
    "GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT", "1SA", "2SA",
    "1KI", "2KI", "1CH", "2CH", "EZR", "NEH", "EST", "JOB", "PSA", "PRO",
    "ECC", "SNG", "ISA", "JER", "LAM", "EZK", "DAN", "HOS", "JOL", "AMO",
    "OBA", "JON", "MIC", "NAM", "HAB", "ZEP", "HAG", "ZEC", "MAL", "MAT",
    "MRK", "LUK", "JHN", "ACT", "ROM", "1CO", "2CO", "GAL", "EPH", "PHP",
    "COL", "1TH", "2TH", "1TI", "2TI", "TIT", "PHM", "HEB", "JAS", "1PE",
    "2PE", "1JN", "2JN", "3JN", "JUD", "REV",
]

INLINE_BLOCKS = re.compile(r"\\(?:f|x)\s.*?\\(?:f|x)\*", re.DOTALL)
WORD_MARKER = re.compile(r"\\w\s+([^|\\]+)(?:\|[^\\]*)?\\w\*")
CHAR_MARKERS = re.compile(r"\\(?:add|bd|bdit|bk|dc|em|it|k|lit|nd|ord|pn|qt|sc|sig|sls|tl|wj)\*?")
ANY_MARKER = re.compile(r"\\[A-Za-z0-9]+\*?(?:\s+)?")


@dataclass(frozen=True)
class Translation:
    source: Path
    output: Path
    language: str
    version: str
    code: str
    title: str
    abbreviation: str
    license: str
    source_url: str


def clean_text(value: str) -> str:
    value = INLINE_BLOCKS.sub("", value)
    value = WORD_MARKER.sub(r"\1", value)
    value = CHAR_MARKERS.sub("", value)
    value = ANY_MARKER.sub("", value)
    value = value.replace("~", " ").replace("//", " ")
    return re.sub(r"\s+", " ", value).strip()


def verse_numbers(label: str) -> list[int]:
    match = re.fullmatch(r"(\d+)(?:-(\d+))?[a-z]?", label)
    if not match:
        raise ValueError(f"Unsupported verse label: {label!r}")
    start = int(match.group(1))
    end = int(match.group(2) or start)
    if end < start or end - start > 10:
        raise ValueError(f"Invalid verse range: {label!r}")
    return list(range(start, end + 1))


def parse_book(path: Path, template_book: dict, expected_code: str) -> dict:
    text = path.read_text(encoding="utf-8-sig")
    id_match = re.search(r"^\\id\s+(\w+)", text, re.MULTILINE)
    if not id_match or id_match.group(1).upper() != expected_code:
        raise ValueError(f"{path}: expected {expected_code}, found {id_match.group(1) if id_match else None}")
    name_match = re.search(r"^\\toc2\s+(.+)$", text, re.MULTILINE)
    name = clean_text(name_match.group(1)) if name_match else template_book["name"]
    chapters: list[dict] = []
    current_chapter: dict | None = None
    current_label: str | None = None
    current_parts: list[str] = []

    def flush_verse() -> None:
        nonlocal current_label, current_parts
        if current_chapter is None or current_label is None:
            return
        cleaned = clean_text(" ".join(current_parts))
        if not cleaned:
            raise ValueError(f"{path}: empty verse {current_chapter['number']}:{current_label}")
        numbers = verse_numbers(current_label)
        for number in numbers:
            current_chapter["verses"].append({
                "number": number,
                "text": cleaned,
                **({"source_label": current_label} if len(numbers) > 1 else {}),
            })
        current_label = None
        current_parts = []

    for raw_line in text.splitlines():
        line = raw_line.strip()
        chapter_match = re.match(r"^\\c\s+(\d+)", line)
        if chapter_match:
            flush_verse()
            current_chapter = {"number": int(chapter_match.group(1)), "verses": []}
            chapters.append(current_chapter)
            continue
        verse_match = re.match(r"^\\v\s+([^\s]+)\s*(.*)$", line)
        if verse_match:
            flush_verse()
            if current_chapter is None:
                raise ValueError(f"{path}: verse before chapter")
            current_label = verse_match.group(1)
            current_parts = [verse_match.group(2)]
            continue
        if current_label is not None and line:
            continuation = re.sub(r"^\\(?:q\d?|m|mi|pi\d?|pc|pr|cls)\s*", "", line)
            if not continuation.startswith("\\"):
                current_parts.append(continuation)
    flush_verse()

    if not chapters or any(not chapter["verses"] for chapter in chapters):
        raise ValueError(f"{path}: missing chapter or verse content")
    for expected, chapter in enumerate(chapters, 1):
        if chapter["number"] != expected:
            raise ValueError(f"{path}: non-sequential chapter {chapter['number']} after {expected - 1}")
        numbers = [verse["number"] for verse in chapter["verses"]]
        if numbers != sorted(set(numbers)):
            raise ValueError(f"{path}: duplicate/out-of-order verses in chapter {expected}")
    return {
        "id": template_book["id"],
        "name": name,
        "abbr": template_book["abbr"],
        "chapters": chapters,
    }


def convert(spec: Translation, template_books: list[dict]) -> dict:
    files = list(spec.source.rglob("*.usfm")) + list(spec.source.rglob("*.SFM"))
    by_code: dict[str, Path] = {}
    for path in files:
        stem = path.stem.upper()
        for code in BOOK_CODES:
            if re.search(rf"(?:^|[-_]){re.escape(code)}", stem):
                by_code[code] = path
                break
    missing = [code for code in BOOK_CODES if code not in by_code]
    if missing:
        raise ValueError(f"{spec.source}: missing books {missing}")
    books = [parse_book(by_code[code], template_books[index], code) for index, code in enumerate(BOOK_CODES)]
    payload = {
        "meta": {
            "language": spec.language,
            "version": spec.version,
            "code": spec.code,
            "title": spec.title,
            "abbreviation": spec.abbreviation,
            "license": spec.license,
            "source_url": spec.source_url,
        },
        "books": books,
    }
    spec.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return payload


def main() -> None:
    template = json.loads(Path("migration_sources/bible_en_niv.json").read_text(encoding="utf-8"))["books"]
    specs = [
        Translation(Path("open_bible_sources/tagalog_open/release/USX_1"), Path("migration_sources/bible_tl_open_asnd.json"), "Tagalog", "Biblica Open Ang Salita ng Diyos 2025", "tl_open_asnd", "TAGALOG - OPEN ANG SALITA NG DIYOS", "ASND", "CC BY-SA 4.0; Copyright © 2009, 2011, 2014, 2025 Biblica, Inc.", "https://www.open.bible/bibles/biblica-open-tagalog-contemporary-bible-2025"),
        Translation(Path("open_bible_sources/cebuano_ocb"), Path("migration_sources/bible_ceb_open_apd.json"), "Cebuano", "Biblica Open Ang Pulong sa Dios", "ceb_open_apd", "BISAYA - OPEN ANG PULONG SA DIOS", "APD", "CC BY-SA 4.0; Copyright © 2009, 2010, 2014, 2024 Biblica, Inc.", "https://ebible.org/cebocb/copyright.htm"),
        Translation(Path("open_bible_sources/cebuano_ulb"), Path("migration_sources/bible_ceb_balaan.json"), "Cebuano", "Balaan nga Bibliya", "ceb_balaan", "BISAYA - BALAAN NGA BIBLIYA", "BNB", "CC BY-SA 4.0; Copyright © 2019 Door43 World Missions Community", "https://ebible.org/cebulb/copyright.htm"),
    ]
    for spec in specs:
        data = convert(spec, template)
        chapters = sum(len(book["chapters"]) for book in data["books"])
        verses = sum(len(chapter["verses"]) for book in data["books"] for chapter in book["chapters"])
        print(f"{spec.code}: books={len(data['books'])}, chapters={chapters}, verses={verses}")


if __name__ == "__main__":
    main()
