#!/usr/bin/env bash
# Patch Data/Index.json on this fork and open a PR against FreeCAD/Addons.
# INTERNAL to .github/workflows/index-release.yml (repository_dispatch).

set -euo pipefail

if [[ "${INDEX_PR_AUTHORIZED:-}" != "true" ]]; then
  echo "open-index-pr.sh is internal to index-release.yml on CREATeNG/FreeCAD-Addons." >&2
  exit 2
fi

RELEASE_TAG="${RELEASE_TAG:?RELEASE_TAG is required}"
RELEASE_VERSION="${RELEASE_VERSION:-${RELEASE_TAG#v}}"
ADDONS_INDEX_FORK_REPO="${ADDONS_INDEX_FORK_REPO:-CREATeNG/FreeCAD-Addons}"
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
  existing_pr="$(
    gh pr list \
      --repo "$ADDONS_INDEX_UPSTREAM_REPO" \
      --head "${ADDONS_INDEX_FORK_REPO%%/*}:${BRANCH}" \
      --state open \
      --json url \
      --jq '.[0].url // empty'
  )"
  if [[ -n "$existing_pr" ]]; then
    set_output index_pr_status existing
    set_output index_pr_url "$existing_pr"
    echo "Index entry already at ${RELEASE_TAG}. Open PR: ${existing_pr}"
    exit 0
  fi

  set_output index_pr_status unchanged
  set_output index_pr_url ""
  echo "Index entry already lists ${RELEASE_TAG}; no new PR opened."
  exit 0
fi

git checkout -B "$BRANCH"
git add "$INDEX_PATH"
git commit -m "Index: ${ADDONS_INDEX_ENTRY_ID} ${RELEASE_TAG}"
git push --force-with-lease origin "$BRANCH"

pr_body="$(cat <<EOF
Automated Index update from [CREATeNG/freecad-mcp-bridge](${ADDON_REPO_URL}) release \`${RELEASE_TAG}\`.

- Entry: \`${ADDONS_INDEX_ENTRY_ID}\`
- Updates \`git_ref\`, \`branch_display_name\`, and \`zip_url\`

FreeCAD Addon Index maintainers review and merge.
EOF
)"

pr_url="$(
  gh pr create \
    --repo "$ADDONS_INDEX_UPSTREAM_REPO" \
    --head "${ADDONS_INDEX_FORK_REPO%%/*}:${BRANCH}" \
    --base "$ADDONS_INDEX_UPSTREAM_BRANCH" \
    --title "Index: ${ADDONS_INDEX_ENTRY_ID} ${RELEASE_TAG}" \
    --body "$pr_body"
)"

set_output index_pr_status opened
set_output index_pr_url "$pr_url"
echo "Opened FreeCAD Addon Index PR: ${pr_url}"