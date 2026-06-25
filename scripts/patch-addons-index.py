#!/usr/bin/env python3
"""Patch Data/Index.json for a freecad-mcp-bridge release. Internal CI helper."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def insert_entry(data: dict, entry_id: str, entry: list[dict]) -> dict:
    if entry_id in data:
        raise ValueError(f"entry already exists: {entry_id}")

    ordered: dict = {}
    inserted = False
    for key, value in data.items():
        if not inserted and key not in ("$schema", "_meta") and entry_id < key:
            ordered[entry_id] = entry
            inserted = True
        ordered[key] = value
    if not inserted:
        ordered[entry_id] = entry
    return ordered


def patch_index(
    data: dict,
    *,
    entry_id: str,
    tag: str,
    repo_url: str,
    allow_add: bool,
) -> tuple[dict, bool]:
    zip_url = f"{repo_url}/archive/refs/tags/{tag}.zip"
    fields = {
        "repository": repo_url,
        "git_ref": tag,
        "branch_display_name": tag,
        "zip_url": zip_url,
    }

    if entry_id in data:
        entries = data[entry_id]
        if not isinstance(entries, list) or not entries:
            raise ValueError(f"invalid entry list for {entry_id}")

        changed = False
        for item in entries:
            if not isinstance(item, dict):
                continue
            for key, value in fields.items():
                if item.get(key) != value:
                    item[key] = value
                    changed = True
            if item.get("curated") is not True:
                item["curated"] = True
                changed = True
        return data, changed

    if not allow_add:
        raise ValueError(f"entry not found: {entry_id}")

    new_entry = {**fields, "curated": True}
    return insert_entry(data, entry_id, [new_entry]), True


def main() -> int:
    if len(sys.argv) != 6:
        print(
            "usage: patch-addons-index.py <index.json> <entry_id> <tag> <repo_url> <allow_add>",
            file=sys.stderr,
        )
        return 2

    path = Path(sys.argv[1])
    entry_id = sys.argv[2]
    tag = sys.argv[3]
    repo_url = sys.argv[4].rstrip("/")
    allow_add = sys.argv[5].lower() == "true"

    data = json.loads(path.read_text(encoding="utf-8"))
    updated, changed = patch_index(
        data,
        entry_id=entry_id,
        tag=tag,
        repo_url=repo_url,
        allow_add=allow_add,
    )

    if changed:
        path.write_text(
            json.dumps(updated, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print(f"Patched {entry_id} for {tag}")
    else:
        print(f"No changes needed for {entry_id} ({tag})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())