#!/bin/bash

set -e

# Argument parsing.
TARBALL="$(realpath "$1")"
OUT="$(realpath "$2")"

# Extract.
tar xf "${TARBALL}" -O cppreference-doxygen-web.tag.xml > "${OUT}"
