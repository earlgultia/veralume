import json
import sqlite3
import unittest
from pathlib import Path


class ImportedBibleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db = sqlite3.connect(Path("assets/data/veralume.db"))
        cls.report = json.loads(Path("docs/data-validation-report.json").read_text(encoding="utf-8"))

    @classmethod
    def tearDownClass(cls):
        cls.db.close()

    def test_integrity_and_counts(self):
        self.assertEqual("ok", self.db.execute("PRAGMA integrity_check").fetchone()[0])
        self.assertEqual((8, 528, 9512, 248314), tuple(self.report["stats"].values()))

    def test_each_version_has_canonical_books(self):
        rows = self.db.execute("SELECT version_id,count(*),min(book_order),max(book_order) FROM books GROUP BY version_id").fetchall()
        self.assertEqual([(version, 66, 1, 66) for version in range(1, 9)], rows)

    def test_no_duplicates_empty_text_or_broken_relationships(self):
        duplicates = self.db.execute("SELECT count(*) FROM (SELECT version_id,book_id,chapter_number,verse_number,count(*) c FROM verses GROUP BY 1,2,3,4 HAVING c>1)").fetchone()[0]
        self.assertEqual(0, duplicates)
        self.assertEqual(0, self.db.execute("SELECT count(*) FROM verses WHERE trim(text)='' ").fetchone()[0])
        self.assertEqual([], self.db.execute("PRAGMA foreign_key_check").fetchall())

    def test_unicode_and_expected_first_verses(self):
        rows = self.db.execute("SELECT bv.code,v.text FROM verses v JOIN bible_versions bv ON bv.id=v.version_id JOIN books b ON b.id=v.book_id WHERE b.book_order=1 AND v.chapter_number=1 AND v.verse_number=1 ORDER BY bv.id").fetchall()
        self.assertEqual("en_asv", rows[0][0])
        self.assertIn("beginning", rows[0][1])
        self.assertIn("Dios", rows[2][1])

    def test_expected_versions_and_licenses(self):
        codes = {row[0] for row in self.db.execute("SELECT code FROM bible_versions")}
        self.assertNotIn("en_isv", codes)
        self.assertIn("ceb_mbb", codes)
        self.assertIn("ceb_bugna", codes)
        self.assertIn("tl_open_asnd", codes)


if __name__ == "__main__":
    unittest.main()
