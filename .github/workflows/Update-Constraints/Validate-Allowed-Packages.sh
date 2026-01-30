#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-2.1-or-later
# SPDX-FileNotice: Part of the FreeCAD project.


set -euo pipefail

file='Data/Python/Allowed-Packages'

test -f "$file" || { echo "::error file=$file::File not found"; exit 1; }

export LC_ALL=C 

awk -f .github/workflows/Update-Constraints/Validate-Allowed-Packages.awk "$file"