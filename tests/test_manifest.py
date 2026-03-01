import tempfile
import unittest
from pathlib import Path

from src.storage.manifest import build_manifest


class ManifestTests(unittest.TestCase):
    def test_build_manifest_sorts_by_date_desc_and_language(self):
        with tempfile.TemporaryDirectory() as tmp:
            posts_dir = Path(tmp) / "_posts"
            posts_dir.mkdir(parents=True)

            (posts_dir / "2026-02-28-summary-en.md").write_text(
                "---\ntitle: \"Horizon Summary: 2026-02-28 (EN)\"\nlang: en\n---\n\n# Body\n",
                encoding="utf-8",
            )
            (posts_dir / "2026-03-01-summary-zh.md").write_text(
                "---\ntitle: \"Horizon Summary: 2026-03-01 (ZH)\"\nlang: zh\n---\n\n# Body\n",
                encoding="utf-8",
            )
            (posts_dir / "invalid.md").write_text("x", encoding="utf-8")

            manifest = build_manifest(posts_dir, "https://example.com/")

            self.assertEqual(manifest["version"], "1")
            self.assertEqual(len(manifest["items"]), 2)
            self.assertEqual(manifest["items"][0]["id"], "2026-03-01-zh")
            self.assertEqual(manifest["items"][1]["id"], "2026-02-28-en")
            self.assertEqual(
                manifest["items"][0]["url"],
                "https://example.com/_posts/2026-03-01-summary-zh.md",
            )


if __name__ == "__main__":
    unittest.main()
