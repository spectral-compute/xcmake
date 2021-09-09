#!/bin/bash

set -e

# Argument parsing.
TARBALL="$(realpath "$1")"
OUT="$(realpath "$2")"

# Generate a sed script by concatenating the sub-scripts listed in this array.
REPLACEMENTS=(
    # There's actually a std::move in <algorithm> too, and this confuses doxygen.
    's|<name>move \(utility\)</name>|<name>move</name>|'
)
for R in "${REPLACEMENTS[@]}" ; do
    SED_SCRIPT="${SED_SCRIPT}${R};"
done

# Extract and filter. --force-local is required because Windows treats the `:` in a path as belonging to
# a remote machine. For example, `C:/`...
tar xf "${TARBALL}" --force-local -O cppreference-doxygen-web.tag.xml | sed -E "${SED_SCRIPT}" > "${OUT}"