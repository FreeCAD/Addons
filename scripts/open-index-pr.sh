#!/usr/bin/env bash
# Patch Data/Index.json on this fork and push an index branch.
# Upstream PR is opened from freecad-mcp-bridge (PAT). INTERNAL to index-release.yml.

set -euo pipefail

if [[ "${INDEX_PR_AUTHORIZED:-}" != "true" ]]; then
  echo "open-index-pr.sh is internal to index-release.yml on CREATeNG/FreeCAD-Addons." >&2
  exit 2
fi

RELEASE_TAG="${RELEASE_TAG:?RELEASE_TAG is required}"
RELEASE_VERSION="${RELEASE_VERSION:-${RELEASE_TAG#v}}"
ADDONS_INDEX_UPSTREAM_REPO="${ADDONS_INDEX_UPSTREAM_REPO:-FreeCAD/Addons}"
ADDONS_INDEX_UPSTREAM_BRANCH="${ADDONS_INDEX_UPSTREAM_BRANCH:-main}"
ADDONS_INDEX_ENTRY_ID="${ADDONS_INDEX_ENTRY_ID:-freecad-mcp-bridge}"
ADDON_REPO_URL="${ADDON_REPO_URL:-https://github.com/CREATeNG/freecad-mcp-bridge}"
ADDONS_INDEX_ALLOW_ADD="${ADDONS_INDEX_ALLOW_ADD:-true}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANCH="index/${ADDONS_INDEX_ENTRY_ID}-${RELEASE_TAG}"
INDEX_PATH="Data/Index.json"

set_output() {
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$1" "$2" >>"$GITHUB_OUTPUT"
  fi
}

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "GH_TOKEN is required." >&2
  exit 1
fi

if ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream "https://github.com/${ADDONS_INDEX_UPSTREAM_REPO}.git"
fi

git fetch upstream "$ADDONS_INDEX_UPSTREAM_BRANCH"
git merge "upstream/${ADDONS_INDEX_UPSTREAM_BRANCH}" --no-edit -m "Sync upstream before ${RELEASE_TAG} index PR"
git push origin "HEAD:${ADDONS_INDEX_UPSTREAM_BRANCH}" || true

if [[ ! -f "$INDEX_PATH" ]]; then
  echo "Missing ${INDEX_PATH}." >&2
  exit 1
fi

before_hash=$(sha256sum "$INDEX_PATH" | awk '{print $1}')
python3 "${SCRIPT_DIR}/patch-addons-index.py" \
  "$INDEX_PATH" \
  "$ADDONS_INDEX_ENTRY_ID" \
  "$RELEASE_TAG" \
  "$ADDON_REPO_URL" \
  "$ADDONS_INDEX_ALLOW_ADD"
after_hash=$(sha256sum "$INDEX_PATH" | awk '{print $1}')

if [[ "$before_hash" == "$after_hash" ]]; then
  set_output index_pr_status unchanged
  set_output index_pr_branch ""
  echo "Index entry already lists ${RELEASE_TAG}; no branch pushed."
  exit 0
fi

git checkout -B "$BRANCH"
git add "$INDEX_PATH"
git commit -m "Index: ${ADDONS_INDEX_ENTRY_ID} ${RELEASE_TAG}"
git push --force-with-lease origin "$BRANCH"

set_output index_pr_status branch_pushed
set_output index_pr_branch "$BRANCH"
echo "Pushed ${BRANCH} to origin (upstream PR opened from freecad-mcp-bridge)."