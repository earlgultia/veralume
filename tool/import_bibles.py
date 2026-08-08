"""Build and validate Veralume's offline SQLite Bible database.

Only translations whose redistribution status is explicitly approved below are
packaged. Source filenames are never trusted; embedded metadata is authoritative.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from dataclasses import dataclass
from pathlib import Path


APPROVED = {
    "en_kjv": ("Public domain (except Crown rights restrictions may apply in the UK)", "KJV"),
    "en_asv": ("Public domain; first published 1901", "ASV"),
    "tl_ang_biblia": ("Public domain source identified by APK metadata", "ADB"),
    "tl_open_asnd": ("CC BY-SA 4.0; Copyright © 2009, 2011, 2014, 2025 Biblica, Inc.", "ASND"),
    "ceb_open_apd": ("CC BY-SA 4.0; Copyright © 2009, 2010, 2014, 2024 Biblica, Inc.", "APD"),
    "ceb_balaan": ("CC BY-SA 4.0; Copyright © 2019 Door43 World Missions Community", "BNB"),
    "ceb_mbb": ("CC BY-ND 4.0; Copyright © 1999 Philippine Bible Society", "MBB-CEB"),
    "ceb_bugna": ("Public domain; Cebuano Ang Biblia, Bugna Version (1917)", "CebBugna"),
}

VERSION_ORDER = [
    "en_asv", "en_kjv", "tl_ang_biblia", "tl_open_asnd",
    "ceb_open_apd", "ceb_balaan", "ceb_mbb", "ceb_bugna",
]


@dataclass
class Stats:
    versions: int = 0
    books: int = 0
    chapters: int = 0
    verses: int = 0


SCHEMA = """
PRAGMA foreign_keys=ON;
CREATE TABLE bible_versions(
 id INTEGER PRIMARY KEY, code TEXT NOT NULL UNIQUE, name TEXT NOT NULL,
 abbreviation TEXT NOT NULL, language TEXT NOT NULL, license TEXT NOT NULL);
CREATE TABLE books(
 id INTEGER PRIMARY KEY, version_id INTEGER NOT NULL REFERENCES bible_versions(id),
 source_id TEXT NOT NULL, name TEXT NOT NULL, abbreviation TEXT NOT NULL,
 testament TEXT NOT NULL CHECK(testament IN ('OT','NT')), book_order INTEGER NOT NULL,
 UNIQUE(version_id, book_order));
CREATE TABLE chapters(
 id INTEGER PRIMARY KEY, book_id INTEGER NOT NULL REFERENCES books(id),
 chapter_number INTEGER NOT NULL CHECK(chapter_number>0), UNIQUE(book_id, chapter_number));
CREATE TABLE verses(
 id INTEGER PRIMARY KEY, version_id INTEGER NOT NULL REFERENCES bible_versions(id),
 book_id INTEGER NOT NULL REFERENCES books(id), chapter_id INTEGER NOT NULL REFERENCES chapters(id),
 chapter_number INTEGER NOT NULL, verse_number INTEGER NOT NULL CHECK(verse_number>0),
 text TEXT NOT NULL CHECK(length(trim(text))>0), UNIQUE(version_id, book_id, chapter_number, verse_number));
CREATE INDEX verses_lookup ON verses(version_id,book_id,chapter_number,verse_number);
CREATE VIRTUAL TABLE verses_fts USING fts5(text, content='verses', content_rowid='id', tokenize='unicode61 remove_diacritics 2');
CREATE TRIGGER verses_ai AFTER INSERT ON verses BEGIN INSERT INTO verses_fts(rowid,text) VALUES(new.id,new.text); END;
"""


def validate_source(data: dict, path: Path) -> list[str]:
    errors: list[str] = []
    books = data.get("books")
    if not isinstance(books, list) or len(books) != 66:
        errors.append(f"{path.name}: expected 66 books, found {len(books or [])}")
        return errors
    seen_books: set[str] = set()
    for book_index, book in enumerate(books, 1):
        book_id = str(book.get("id", ""))
        if not book_id or book_id in seen_books:
            errors.append(f"{path.name}: invalid/duplicate book id {book_id!r}")
        seen_books.add(book_id)
        chapters = book.get("chapters", [])
        for expected_chapter, chapter in enumerate(chapters, 1):
            if chapter.get("number") != expected_chapter:
                errors.append(f"{path.name}/{book_id}: chapter sequence error at {expected_chapter}")
            seen_verses: set[int] = set()
            previous_verse = 0
            for verse in chapter.get("verses", []):
                number = verse.get("number")
                if not isinstance(number, int) or number <= previous_verse or number in seen_verses:
                    errors.append(f"{path.name}/{book_id}/{expected_chapter}: invalid/out-of-order verse {number}")
                    continue
                seen_verses.add(number)
                previous_verse = number
                if not str(verse.get("text", "")).strip():
                    errors.append(f"{path.name}/{book_id}/{expected_chapter}:{number}: empty text")
    return errors


def build(source_dir: Path, output: Path, report: Path) -> Stats:
    files = sorted(source_dir.glob("bible_*.json"))
    if not files:
        raise SystemExit(f"No Bible JSON files found in {source_dir}")
    inspected: list[dict] = []
    approved: list[tuple[Path, dict]] = []
    all_errors: list[str] = []
    for path in files:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
        meta = data.get("meta", {})
        code = meta.get("code", "")
        errors = validate_source(data, path)
        if code in APPROVED:
            all_errors.extend(errors)
        inspected.append({"file": path.name, "meta": meta, "books": len(data.get("books", [])),
                          "approved": code in APPROVED, "validation_errors": errors})
        if code in APPROVED:
            approved.append((path, data))
    order = {code: index for index, code in enumerate(VERSION_ORDER)}
    approved.sort(key=lambda item: order[item[1]["meta"]["code"]])
    if all_errors:
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(json.dumps({"inspected": inspected, "errors": all_errors}, ensure_ascii=False, indent=2), encoding="utf-8")
        raise SystemExit(f"Validation failed with {len(all_errors)} error(s); see {report}")

    output.parent.mkdir(parents=True, exist_ok=True)
    output.unlink(missing_ok=True)
    db = sqlite3.connect(output)
    db.executescript(SCHEMA)
    stats = Stats()
    try:
        for version_id, (_, data) in enumerate(approved, 1):
            meta = data["meta"]
            license_text, abbreviation = APPROVED[meta["code"]]
            db.execute("INSERT INTO bible_versions VALUES(?,?,?,?,?,?)",
                       (version_id, meta["code"], meta["title"], abbreviation, meta["language"], license_text))
            stats.versions += 1
            for order, book in enumerate(data["books"], 1):
                cursor = db.execute("INSERT INTO books(version_id,source_id,name,abbreviation,testament,book_order) VALUES(?,?,?,?,?,?)",
                                    (version_id, book["id"], book["name"], book["abbr"], "OT" if order <= 39 else "NT", order))
                book_db_id = cursor.lastrowid
                stats.books += 1
                for chapter in book["chapters"]:
                    cursor = db.execute("INSERT INTO chapters(book_id,chapter_number) VALUES(?,?)",
                                        (book_db_id, chapter["number"]))
                    chapter_id = cursor.lastrowid
                    stats.chapters += 1
                    rows = [(version_id, book_db_id, chapter_id, chapter["number"], verse["number"], verse["text"])
                            for verse in chapter["verses"]]
                    db.executemany("INSERT INTO verses(version_id,book_id,chapter_id,chapter_number,verse_number,text) VALUES(?,?,?,?,?,?)", rows)
                    stats.verses += len(rows)
        db.commit()
        integrity = db.execute("PRAGMA integrity_check").fetchone()[0]
        foreign_keys = db.execute("PRAGMA foreign_key_check").fetchall()
        duplicates = db.execute("SELECT count(*) FROM (SELECT version_id,book_id,chapter_number,verse_number,count(*) c FROM verses GROUP BY 1,2,3,4 HAVING c>1)").fetchone()[0]
        empty = db.execute("SELECT count(*) FROM verses WHERE length(trim(text))=0").fetchone()[0]
        if integrity != "ok" or foreign_keys or duplicates or empty:
            raise RuntimeError(f"Database validation failed: integrity={integrity}, fk={len(foreign_keys)}, duplicates={duplicates}, empty={empty}")
    finally:
        db.close()
    payload = {"source": str(source_dir), "output": str(output), "stats": stats.__dict__,
               "integrity": "ok", "inspected": inspected,
               "excluded_reason": "No verified full-text redistribution permission"}
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return stats


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=Path("migration_sources"))
    parser.add_argument("--output", type=Path, default=Path("assets/data/veralume.db"))
    parser.add_argument("--report", type=Path, default=Path("docs/data-validation-report.json"))
    args = parser.parse_args()
    print(build(args.source, args.output, args.report))
