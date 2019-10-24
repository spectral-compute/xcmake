# Rewrite URLs in markdown files.

INPUT_FILE="$1"
OUTPUT_FILE="$2"
DOTSLASHES="$3"
shift 3
REPLACEMENTS="$@"

# Use sed to turn the input cmake list literal into a sed program.
# The input is of the form:
# <URL to match>|<Replacement>
# <Replacement> is a relative path from the root of the install tree. The idea is that the given
# URL to match is equivalent to `./<Replacement>` in the install tree.
# We prepend $DOTSLASHES to `<Replacement>` to eliminate any subdirectories the input .md file
# might be inside, and then reformat the list as a list of simple replace commands.
REPLACEMENT_SED=$(echo $REPLACEMENTS | sed -Ee 's#\|#|'$DOTSLASHES'#g;s/ /|g;s|/g;s/^/s|/;s/$/|g/')

# Run said sed program, along with a two default rules:
# - Replace `README.md` in hyperlinks with `index.html`
# - Replace all relative hyperlinks that point to *.md to point to *.html instead.
cat "$INPUT_FILE" | sed -Ee $REPLACEMENT_SED';s|README.md\)|index.html)|g;s|(\[[^]]+\])\(([^)]+).md\)|\1(\2.html)|g' > "$OUTPUT_FILE"
