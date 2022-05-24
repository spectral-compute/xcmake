#!/bin/bash

# A script to generate documentation for a standalone (i.e: not xcmake) project.
# Usage: standalone.sh DocsSource OutDirectory Name [UrlRewriterReplacement]... -- [PreprocessorArgument]

set -e

TOOLSDIR="$(realpath "$(dirname "$0")")"

# Positional arguments.
SRCDIR="$(realpath $1)"
OUTDIR="$(realpath $2)"
NAME="$3"
shift 3

# URL rewriter arguments.
URL_REWRITER_ARGS=()
while [ "$#" != "0" ] && [ "$1" != "--" ] ; do
    URL_REWRITER_ARGS+=("$1")
    shift
done
shift

# Preprocessor arguments.
PREPROCESSOR_ARGS=("$@")

# Other variables.
TMP_PREFIX="/tmp/${NAME}-docs"

function buildMarkdown
{
    SRC="$1"

    # Figure out where to output to.
    if echo "${SRC}" | grep -qE '^private/' ; then
        DOCSDIR="private_docs"
    else
        DOCSDIR="docs"
    fi
    OUTHTML="${OUTDIR}/${DOCSDIR}/${NAME}/$(echo "${SRC}" | sed -E 's/[.]md$/.html/;s/README[.]html$/index.html/')"
    DOTSLASHES="$(dirname "${SRC}" | sed -E 's/^[.]$//;s|[^/]+|..|g;s|..$|../|')"

    # Print a nice message :)
    echo -e "Building \x1b[1m${SRCDIR}/${SRC}\x1b[m -> ${OUTHTML}"

    # Create output directory.
    mkdir -p "$(dirname "${OUTHTML}")"

    # Preprocess the markdown.
    "${TOOLSDIR}/preprocessor.py" "${PREPROCESSOR_ARGS[@]}" -i "${SRCDIR}/${SRC}" -o "${TMP_PREFIX}-preprocess"

    # Rewrite the URLs in the markdown.
    "${TOOLSDIR}/url-rewriter.sh" ${TMP_PREFIX}-preprocess "${TMP_PREFIX}-url-rewrite" "${NAME}" "${DOTSLASHES}" \
                                  "${URL_REWRITER_ARGS[@]}"

    # Generate HTML
    pandoc --fail-if-warnings --toc --from markdown --to html --standalone --css "${DOTSLASHES}style.css" \
           "${TMP_PREFIX}-url-rewrite" > "${OUTHTML}"

    # Clean up.
    rm "${TMP_PREFIX}"-{preprocess,url-rewrite}

    # Make sure the style sheet is in place (this gets called many times for one directory, but that's OK).
    cp "${TOOLSDIR}/style.css" "${OUTDIR}/${DOCSDIR}/${NAME}/style.css"
}

(
    set -e
    cd "${SRCDIR}"
    IFS=$'\n'
    for F in $(find | grep -E '[.]md$') ; do
        F="$(echo "$F" | sed -E "s|^[.]/||")"
        if echo "${F}" | grep -qF "xcmake" ; then
            continue
        fi
        buildMarkdown "${F}"
    done
)
