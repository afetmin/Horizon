"""Helpers for building summary manifests for Pages and mobile clients."""

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


def _iter_post_metadata(posts_dir: Path):
    if not posts_dir.exists():
        return

    for path in posts_dir.glob("*-summary-*.md"):
        match = POST_FILE_PATTERN.match(path.name)
        if not match:
            continue
        date = match.group("date")
        lang = match.group("lang")
        title = _read_front_matter_title(path, date, lang)
        yield path, date, lang, title


def build_manifest(posts_dir: Path, base_url: str | None = None, generated_at: datetime | None = None) -> dict:
    """Build a stable JSON manifest from generated post markdown files."""
    normalized_base = (base_url or "").rstrip("/")
    now = generated_at or datetime.now(timezone.utc)

    items = []
    for path, date, lang, title in _iter_post_metadata(posts_dir):
        relative_path = f"/_posts/{path.name}"
        url = f"{normalized_base}{relative_path}" if normalized_base else relative_path
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


def build_release_manifest(
    posts_dir: Path,
    repository: str,
    release_tag: str = "mobile-feed",
    generated_at: datetime | None = None,
) -> dict:
    """Build a mobile manifest that points to GitHub release asset URLs."""
    now = generated_at or datetime.now(timezone.utc)
    repository_name = repository.strip().strip("/")
    tag_name = release_tag.strip()

    items = []
    for path, date, lang, title in _iter_post_metadata(posts_dir):
        items.append(
            {
                "id": f"{date}-{lang}",
                "date": date,
                "lang": lang,
                "title": title,
                "url": _build_release_asset_url(repository_name, tag_name, path.name),
            }
        )

    items.sort(key=lambda x: (x["date"], x["lang"]), reverse=True)
    return {
        "version": "2",
        "generated_at": now.isoformat().replace("+00:00", "Z"),
        "source": "github-release",
        "release_tag": tag_name,
        "items": items,
    }


def _build_release_asset_url(repository: str, release_tag: str, filename: str) -> str:
    return f"https://github.com/{repository}/releases/download/{release_tag}/{filename}"


def build_mobile_cdn_manifest(
    posts_dir: Path,
    repository: str,
    git_ref: str = "gh-pages",
    generated_at: datetime | None = None,
) -> dict:
    """Build a mobile manifest that points to GitHub repo files via jsDelivr."""
    now = generated_at or datetime.now(timezone.utc)
    repository_name = repository.strip().strip("/")
    ref_name = git_ref.strip() or "gh-pages"

    items = []
    for path, date, lang, title in _iter_post_metadata(posts_dir):
        items.append(
            {
                "id": f"{date}-{lang}",
                "date": date,
                "lang": lang,
                "title": title,
                "url": _build_github_cdn_url(repository_name, ref_name, f"_posts/{path.name}"),
            }
        )

    items.sort(key=lambda x: (x["date"], x["lang"]), reverse=True)
    return {
        "version": "3",
        "generated_at": now.isoformat().replace("+00:00", "Z"),
        "source": "github-cdn",
        "repository": repository_name,
        "git_ref": ref_name,
        "items": items,
    }


def _build_github_cdn_url(repository: str, git_ref: str, file_path: str) -> str:
    normalized_path = file_path.strip().lstrip("/")
    return f"https://cdn.jsdelivr.net/gh/{repository}@{git_ref}/{normalized_path}"


def merge_manifest_items(current_manifest: dict, existing_manifest: dict | None) -> dict:
    """Merge current manifest items with an existing manifest, preferring current items."""
    merged_by_id = {}

    for item in (existing_manifest or {}).get("items", []):
        if isinstance(item, dict) and item.get("id"):
            merged_by_id[item["id"]] = item

    normalized_base = current_manifest.get("base_url", "").rstrip("/")
    for item in current_manifest.get("items", []):
        item_id = item.get("id")
        if not item_id:
            continue
        merged_item = dict(item)
        relative_path = merged_item.get("path", "")
        if normalized_base and relative_path:
            merged_item["url"] = f"{normalized_base}{relative_path}"
        merged_by_id[item_id] = merged_item

    items = list(merged_by_id.values())
    items.sort(key=lambda x: (x.get("date", ""), x.get("lang", "")), reverse=True)

    return {
        "version": current_manifest.get("version", "1"),
        "generated_at": current_manifest.get("generated_at"),
        "base_url": normalized_base,
        "items": items,
    }


def merge_release_manifest_items(current_manifest: dict, existing_manifest: dict | None) -> dict:
    """Merge release-backed mobile manifest items, preferring current items."""
    merged_by_id = {}

    for item in (existing_manifest or {}).get("items", []):
        if isinstance(item, dict) and item.get("id"):
            merged_by_id[item["id"]] = item

    for item in current_manifest.get("items", []):
        item_id = item.get("id")
        if not item_id:
            continue
        merged_by_id[item_id] = dict(item)

    items = list(merged_by_id.values())
    items.sort(key=lambda x: (x.get("date", ""), x.get("lang", "")), reverse=True)

    return {
        "version": current_manifest.get("version", "2"),
        "generated_at": current_manifest.get("generated_at"),
        "source": current_manifest.get("source", "github-release"),
        "release_tag": current_manifest.get("release_tag", "mobile-feed"),
        "items": items,
    }
def read_manifest(path: Path) -> dict | None:
    """Read a manifest JSON file from disk."""
    if not path.exists():
        return None

    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    return data if isinstance(data, dict) else None


def write_manifest(manifest: dict, output_path: Path) -> None:
    """Write manifest JSON to disk."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
