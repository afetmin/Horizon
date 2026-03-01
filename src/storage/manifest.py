"""Helpers for building a mobile-friendly summary manifest."""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path


POST_FILE_PATTERN = re.compile(r"^(?P<date>\d{4}-\d{2}-\d{2})-summary-(?P<lang>[a-z]{2})\.md$")
TITLE_PATTERN = re.compile(r'^title:\s*["\']?(?P<title>.+?)["\']?\s*$')


def _default_title(date: str, lang: str) -> str:
    return f"Horizon Summary: {date} ({lang.upper()})"


def _read_front_matter_title(path: Path, date: str, lang: str) -> str:
    """Extract title from Jekyll front matter with a safe fallback."""
    try:
        content = path.read_text(encoding="utf-8")
    except OSError:
        return _default_title(date, lang)

    if not content.startswith("---\n"):
        return _default_title(date, lang)

    lines = content.splitlines()
    # Only inspect front matter block to avoid false positives in body text.
    for idx in range(1, len(lines)):
        line = lines[idx].strip()
        if line == "---":
            break
        match = TITLE_PATTERN.match(line)
        if match:
            return match.group("title").strip()
    return _default_title(date, lang)


def build_manifest(posts_dir: Path, base_url: str | None = None, generated_at: datetime | None = None) -> dict:
    """Build a stable JSON manifest from generated post markdown files."""
    normalized_base = (base_url or "").rstrip("/")
    now = generated_at or datetime.now(timezone.utc)

    items = []
    if posts_dir.exists():
        for path in posts_dir.glob("*-summary-*.md"):
            match = POST_FILE_PATTERN.match(path.name)
            if not match:
                continue
            date = match.group("date")
            lang = match.group("lang")
            relative_path = f"/_posts/{path.name}"
            url = f"{normalized_base}{relative_path}" if normalized_base else relative_path
            title = _read_front_matter_title(path, date, lang)
            items.append(
                {
                    "id": f"{date}-{lang}",
                    "date": date,
                    "lang": lang,
                    "title": title,
                    "path": relative_path,
                    "url": url,
                }
            )

    items.sort(key=lambda x: (x["date"], x["lang"]), reverse=True)
    return {
        "version": "1",
        "generated_at": now.isoformat().replace("+00:00", "Z"),
        "base_url": normalized_base,
        "items": items,
    }


def write_manifest(manifest: dict, output_path: Path) -> None:
    """Write manifest JSON to disk."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
