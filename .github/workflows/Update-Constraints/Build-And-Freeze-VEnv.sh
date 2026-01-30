#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-2.1-or-later
# SPDX-FileNotice: Part of the FreeCAD project.


set -euo pipefail

python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip

# Prepare allowlist, native deps, NO_BINARY_ARGS, and prune

awk '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/ { next }
    { gsub(/^[[:space:]]+|[[:space:]]+$/,"",$0); print tolower($0) }
' Data/Python/Allowed-Packages > .allowed_names

IFS=',' read -ra NATIVE <<<"${ALLOW_SDIST_NATIVE:-}"

if (( ${#NATIVE[@]} )); then
    sudo apt-get update
    sudo apt-get install -y libsuitesparse-dev
fi

NO_BINARY_ARGS=()

for raw in $(echo "${ALLOW_SDIST_PURE},${ALLOW_SDIST_NATIVE}" | tr ',' ' '); do
    name="$(echo "$raw" | tr 'A-Z' 'a-z' | xargs)"; [[ -z "$name" ]] && continue
    NO_BINARY_ARGS+=( "--no-binary=$name" )
done

PRUNED=.allowed_pruned.txt

cp .allowed_names "$PRUNED"

IFS=',' read -ra EXCL <<<"${EXCLUDE_PACKAGES:-}"

for raw in "${EXCL[@]}"; do
    name="$(echo "$raw" | tr 'A-Z' 'a-z' | xargs)"; [[ -z "$name" ]] && continue
    grep -Fvx "$name" "$PRUNED" > "$PRUNED.tmp" && mv "$PRUNED.tmp" "$PRUNED"
done

# Install with wheels-only except for allowlisted sdists

pip install \
    --require-virtualenv \
    --disable-pip-version-check \
    --no-cache-dir \
    --only-binary=:all: \
    "${NO_BINARY_ARGS[@]}" \
    --index-url https://pypi.org/simple \
    -r "$PRUNED"

py_tag=$(python -c 'import sys; print(f"py{sys.version_info.major}{sys.version_info.minor}")')

mkdir -p constraints

out_basename="constraints-${py_tag}.txt"
out_path="Data/Python/Constraints/${out_basename}"

pip freeze --exclude-editable > "$out_path"

# Expose both basename (artifact name) and path (artifact file)

echo "ARTIFACT_NAME=$out_basename" >> "$GITHUB_ENV"
echo "ARTIFACT_PATH=$out_path" >> "$GITHUB_ENV"