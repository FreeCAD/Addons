#!/usr/bin/env awk
# SPDX-License-Identifier: LGPL-2.1-or-later
# SPDX-FileNotice: Part of the FreeCAD project.

#
#   Only allow comment lines, whitespace, and lines containing 
#   JUST a Python package name (no versions, etc.)
#
#   Take some extra precautions like limiting the max 
#   line length, etc. to prevent strange malicious PRs.
#

BEGIN { 
    bad = 0 
    max = 200
}

function trim(s) {
    sub(/^[ \t]+/, "", s); 
    sub(/[ \t]+$/, "", s); 
    return s 
}

/^[[:space:]]*$/ { next } # Spaces
/^[[:space:]]*#/ { next } # Comments

{
    raw = $0
    line = trim($0)
    
    if (line ~ /^[A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?$/) {
        
        key = tolower(line)
        seen[key]++

        if (length(line) > max) {
            printf("Line %d too long: %s\n", NR, raw) > "/dev/stderr"; 
            bad = 1
        }

        next
    }

    printf("Invalid line %d: %s\n", NR, raw) > "/dev/stderr"; 

    bad = 1
}

END { 

    for (k in seen) if (seen[k] > 1) { 
        printf("Duplicate package: %s\n", k) > "/dev/stderr"; 
        bad = 1 
    }

    exit bad 
}
