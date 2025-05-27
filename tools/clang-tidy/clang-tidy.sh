#!/usr/bin/env bash

SRCDIR="$1"
shift

EXTRA_ARGS=
while echo "$1" | grep -qE '^--extra-arg-before[= ]' ; do
    EXTRA_ARGS="${EXTRA_ARGS} $1"
    shift
done

printError() {
    echo -e "\e[1m\e[97m$1: \e[31merror: \e[97m$2\e[0m"
}

# Function for detecting some kinds of trivial formatting fail.
findFail() {
    REGEX=$1
    FILE=$2
    shift 2

    FAIL=`grep -Pn $REGEX $FILE | head -n 1 | cut -d ':' -f 1`
    if [ ! $FAIL = "" ]; then
        printError $FILE:$FAIL "$@"
        exit 1
    fi
}

# Weed out trivial formatting fails right away...
findFail '\t' $1 "line indented with tab characters"
findFail $'\\s$' $1 "Trailing whitespace"
findFail $'\r'\$ $1 "CRLF detected - use LF instead"

clang-tidy ${EXTRA_ARGS} --use-color --header-filter="$SRCDIR/.*" --vfsoverlay="$(dirname "$0")/vfs.yaml" "$@"
