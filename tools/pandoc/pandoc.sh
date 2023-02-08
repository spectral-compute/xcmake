#!/bin/bash

INPUT="$1"
OUTPUT="$2"
CSS="$3"

# Start building arguments (and some description of what they are).
ARGS=(
    # Filters
    --filter pandoc-include-code

    # Insert a pandoc metadata block at the start of your document to disable this. The opposite configuration (enabling
    # per-document) is not supported by Pandoc.
    --toc
)

# Extract the front matter.
FRONT_MATTER="$(awk '/^---$/{v++;next}{if(v==1)print}' "${INPUT}")"

# Figure out the --toc-depth.
TOC_DEPTH="$(echo "${FRONT_MATTER}" | sed -nE 's/^toc-depth: ([0-9]+)$/\1/;T;p;q')"
if [ ! -z "${TOC_DEPTH}" ] ; then
    ARGS+=(--toc-depth "${TOC_DEPTH}")
fi

# Run pandoc.
pandoc --fail-if-warnings --from markdown --to html --css "${CSS}" --standalone "${INPUT}" "${ARGS[@]}" > "${OUTPUT}"
exit $?
