#!/usr/bin/env bash

# Reverse nvidia's doxygen tag obfuscation.
cat "$1" | sed -n -Ee '1h;1!H;${;g;s|\s+<anchorfile>([a-zA-Z0-9_]+).html</anchorfile>\n\s+<anchor>([a-z0-9])[a-z0-9]([a-z0-9]+)|\n      <anchorfile>\1.html</anchorfile>\n      <anchor>\1_1\2\3|g;p;}' > "$2"
