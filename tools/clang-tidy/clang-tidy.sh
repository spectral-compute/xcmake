#!/usr/bin/env bash

SRCDIR="$1"
shift

EXTRA_ARGS=
while echo "$1" | grep -qE '^--extra-arg-before[= ]' ; do
    EXTRA_ARGS="${EXTRA_ARGS} $1"
    shift
done

printError() {
    echo -e "$1:\e[31m error\e[0m: $2"
}

# Function for detecting some kinds of trivial formatting fail.
findFail() {
    REGEX=$1
    FILE=$2
    shift 2

    FAIL=`grep -Pn "$REGEX" $FILE | head -n 1 | cut -d ':' -f 1`
    if [ ! $FAIL = "" ]; then
        printError $FILE:$FAIL "$@"
        exit 1
    fi
}

# Weed out trivial formatting fails right away...
findFail '\t' $1 "line indented with tab characters"
findFail $'\\s$' $1 "Trailing whitespace"
findFail $'\r'\$ $1 "CRLF detected - use LF instead"
findFail $'NOLINT$' $1 "NOLINT given without diagnostic name"
findFail $'NOLINT[ ]' $1 "NOLINT given without diagnostic name"

if [[ $1 == *.cu ]]; then
  # Skip clang-tidy entirely for CUDA
  shift
  shift
  "$@"
else
  clang-tidy ${EXTRA_ARGS} --use-color --header-filter="$SRCDIR/.*" --vfsoverlay="$(dirname "$0")/vfs.yaml" "$@"
fi

