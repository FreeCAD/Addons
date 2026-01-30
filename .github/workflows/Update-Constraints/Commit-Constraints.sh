#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-2.1-or-later
# SPDX-FileNotice: Part of the FreeCAD project.


set -euo pipefail

git add Data/Python/Constraints/constraints/*.txt || true

if git diff --staged --quiet; then
    echo "No changes to constraints files; nothing to commit."
    exit 0
fi

git config user.name  "freecad-constraints-bot"
git config user.email "freecad-constraints-bot@users.noreply.github.com"
git commit -m "Update constraints based on revised Allowed-Packages content"

repo_url="https://${BOT_PUSH_TOKEN}@github.com/${PR_REPO}.git"

git push "${repo_url}" "HEAD:${PR_REF}"
