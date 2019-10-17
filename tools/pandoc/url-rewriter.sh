# Rewrite URLs in markdown files.

INPUT_FILE="$1"
OUTPUT_FILE="$2"

cat "$INPUT_FILE" | sed -Ee 's|(\[[^]]+\])\(([^)]+).md\)|\1(\2.html)|' > "$OUTPUT_FILE"
