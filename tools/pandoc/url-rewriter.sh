# Rewrite URLs in markdown files.

INPUT_FILE="$1"
OUTPUT_FILE="$2"
RELATIVE_TO="$3"
DOTSLASHES="$4"
shift 4

# Use sed to turn the input cmake list literal into a sed program.
# The inputs are of the form:
# <URL to match>|<Replacement>
# <Replacement> is a relative path from the root of the install tree. The idea is that the given
# URL to match is equivalent to `./<Replacement>` in the install tree.
# We prepend $DOTSLASHES to `<Replacement>` to eliminate any subdirectories the input .md file
# might be inside, make the path relative to $RELATIVE_TO (so it's maximally portable), and then reformat the list as a
# list of simple replace commands.

for ORIGINAL_REPLACEMENT in "$@" ; do
    # The replacement should have the form `OLD|NEW`. Extract the original replacement's components.
    ORIGINAL_REPLACEMENT_LHS="$(echo "$ORIGINAL_REPLACEMENT" | sed -E 's/([^|]*)[|].*/\1/')"
    ORIGINAL_REPLACEMENT_RHS="$(echo "$ORIGINAL_REPLACEMENT" | sed -E 's/[^|]*[|](.*)/\1/')"

    # Strip any trailing / off the end of the thing to replace and make the thing to replace with be as relative as
    # possible (this improves moveability).
    NEW_REPLACEMENT_LHS="$(echo "$ORIGINAL_REPLACEMENT_LHS" | sed -E 's|/$||')"
    NEW_REPLACEMENT_RHS="$(realpath -m --relative-to="$RELATIVE_TO" "$ORIGINAL_REPLACEMENT_RHS")"

    # Build the complete sed script for this replacement.
    NEW_REPLACEMENT="s|${NEW_REPLACEMENT_LHS}|${NEW_REPLACEMENT_RHS}|g"

    # Append the replacement to the complete sed script we're building.
    if [ ! -z "${REPLACEMENT_SED}" ] ; then
        REPLACEMENT_SED="${REPLACEMENT_SED};"
    fi
    REPLACEMENT_SED="${REPLACEMENT_SED}${NEW_REPLACEMENT}"
done

# Run said sed program, along with a two default rules:
# - Replace `README.md` in hyperlinks with `index.html`
# - Replace all relative hyperlinks that point to *.md to point to *.html instead.
cat "$INPUT_FILE" | sed -Ee $REPLACEMENT_SED';s|README.md\)|index.html)|g;s|(\[[^]]+\])\(([^)]+).md\)|\1(\2.html)|g' > "$OUTPUT_FILE"
