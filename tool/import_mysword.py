"""Convert user-supplied MySword SQLite Bible modules to Veralume JSON."""

from __future__ import annotations

import html
import json
import re
import sqlite3
from dataclasses import dataclass
from pathlib import Path


SOURCE_ROOT = Path(r"C:\Users\miles\Desktop\mysword_1\bibles")
TEMPLATE = Path("migration_sources/bible_en_niv.json")


@dataclass(frozen=True)
class Module:
    source: Path
    output: Path
    code: str
    title: str
    abbreviation: str
    license: str


MODULES = (
    Module(
        SOURCE_ROOT / "mbb-ceb.bbl.mybible",
        Path("migration_sources/bible_ceb_mbb.json"),
        "ceb_mbb",
        "BISAYA - MBB-CEB",
        "MBB-CEB",
        "CC BY-ND 4.0; Copyright © 1999 Philippine Bible Society",
    ),
    Module(
        SOURCE_ROOT / "cebbugna.bbl.mybible",
        Path("migration_sources/bible_ceb_bugna.json"),
        "ceb_bugna",
        "BISAYA - CEBBUGNA",
        "CebBugna",
        "Public domain; Cebuano Ang Biblia, Bugna Version (1917)",
    ),
)


def readable_text(source: str) -> str:
    # MySword embeds headings and footnotes in marker pairs. Removing these
    # presentation blocks is format conversion; Scripture wording/punctuation
    # is left unchanged as required by the source module's BY-ND license.
    value = re.sub(r"<RF(?:\s[^>]*)?>.*?<Rf>", "", source, flags=re.DOTALL)
    value = re.sub(r"<TS(?:\s[^>]*)?>.*?<Ts>", "", value, flags=re.DOTALL)
    value = re.sub(r"<[^>]+>", "", value)
    value = html.unescape(value)
    return re.sub(r"\s+", " ", value).strip()


def convert(module: Module, template_books: list[dict]) -> tuple[int, int, int]:
    if not module.source.exists():
        raise FileNotFoundError(module.source)
    connection = sqlite3.connect(f"file:{module.source}?mode=ro", uri=True)
    try:
        details = connection.execute("SELECT * FROM Details LIMIT 1").fetchone()
        rows = connection.execute(
            "SELECT Book,Chapter,Verse,Scripture FROM Bible ORDER BY Book,Chapter,Verse"
        ).fetchall()
    finally:
        connection.close()

    books = []
    row_map = {(book, chapter, verse): scripture for book, chapter, verse, scripture in rows}
    for book_number, template in enumerate(template_books, 1):
        chapter_numbers = sorted({c for b, c, _ in row_map if b == book_number})
        chapters = []
        for chapter_number in chapter_numbers:
            verses = []
            for (book, chapter, verse), scripture in row_map.items():
                if book == book_number and chapter == chapter_number:
                    text = readable_text(scripture)
                    if not text:
                        raise ValueError(f"Empty verse {book}:{chapter}:{verse}")
                    verses.append({"number": verse, "text": text})
            chapters.append({"number": chapter_number, "verses": verses})
        books.append(
            {
                "id": template["id"],
                "name": template["name"],
                "abbr": template["abbr"],
                "chapters": chapters,
            }
        )

    payload = {
        "meta": {
            "language": "Cebuano",
            "version": module.title,
            "code": module.code,
            "title": module.title,
            "abbreviation": module.abbreviation,
            "license": module.license,
            "source": str(module.source),
            "source_details": str(details[0]) if details else "",
        },
        "books": books,
    }
    module.output.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return len(books), sum(len(b["chapters"]) for b in books), len(rows)


def main() -> None:
    template_books = json.loads(TEMPLATE.read_text(encoding="utf-8"))["books"]
    for module in MODULES:
        books, chapters, verses = convert(module, template_books)
        print(f"{module.code}: books={books}, chapters={chapters}, verses={verses}")


if __name__ == "__main__":
    main()
