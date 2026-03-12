import tempfile
import unittest
from pathlib import Path

from src.storage.manifest import build_manifest, build_release_manifest, merge_release_manifest_items


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

    def test_build_release_manifest_uses_release_asset_urls(self):
        with tempfile.TemporaryDirectory() as tmp:
            posts_dir = Path(tmp) / "_posts"
            posts_dir.mkdir(parents=True)

            (posts_dir / "2026-03-12-summary-zh.md").write_text(
                "---\ntitle: \"Horizon Summary: 2026-03-12 (ZH)\"\nlang: zh\n---\n\n# Body\n",
                encoding="utf-8",
            )

            manifest = build_release_manifest(posts_dir, "afetmin/Horizon", "mobile-feed")

            self.assertEqual(manifest["version"], "2")
            self.assertEqual(manifest["source"], "github-release")
            self.assertEqual(manifest["release_tag"], "mobile-feed")
            self.assertEqual(
                manifest["items"][0]["url"],
                "https://github.com/afetmin/Horizon/releases/download/mobile-feed/2026-03-12-summary-zh.md",
            )

    def test_merge_release_manifest_items_keeps_history_and_replaces_duplicate_ids(self):
        current_manifest = {
            "version": "2",
            "generated_at": "2026-03-12T00:00:00Z",
            "source": "github-release",
            "release_tag": "mobile-feed",
            "items": [
                {
                    "id": "2026-03-12-zh",
                    "date": "2026-03-12",
                    "lang": "zh",
                    "title": "New",
                    "url": "https://example.com/new.md",
                }
            ],
        }
        existing_manifest = {
            "version": "2",
            "generated_at": "2026-03-11T00:00:00Z",
            "source": "github-release",
            "release_tag": "mobile-feed",
            "items": [
                {
                    "id": "2026-03-12-zh",
                    "date": "2026-03-12",
                    "lang": "zh",
                    "title": "Old",
                    "url": "https://example.com/old.md",
                },
                {
                    "id": "2026-03-11-en",
                    "date": "2026-03-11",
                    "lang": "en",
                    "title": "History",
                    "url": "https://example.com/history.md",
                },
            ],
        }

        merged = merge_release_manifest_items(current_manifest, existing_manifest)

        self.assertEqual(len(merged["items"]), 2)
        self.assertEqual(merged["items"][0]["id"], "2026-03-12-zh")
        self.assertEqual(merged["items"][0]["title"], "New")
        self.assertEqual(merged["items"][1]["id"], "2026-03-11-en")


if __name__ == "__main__":
    unittest.main()
