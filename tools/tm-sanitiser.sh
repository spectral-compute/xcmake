#!/usr/bin/env bash

# A script to sanitise files for trademark compliance.

# Applies the following rules to the input file:
# - The (r) or ^{tm} symbols cannot appear following any of the trademarks in the input configruation.
#
# A descriptive error is printed and the script returns nonzero if a problem is found.

TARGET=$1
shift

explode() {
    echo -e "\e[1;97m$1:$2: \e[31merror:\e[97m $4:\e[0m"

    # Print the line
    sed "$2q;d" $1 | grep --color=always $3
}

for TM in "$@"; do
    # Who owns the trademark?
    OWNER=$(echo "$TM" | cut -d ' ' -f 1)

    # The mark itself.
    MARK=$(echo "$TM" | cut -d ' ' -f 2- | sed -Ee 's/[™®]//g')

    FINDING=$(cat "$TARGET" | grep -n "$MARK[™®]" | head -n 1)
    LINE=$(echo $FINDING | cut -d ':' -f 1)

    # Has the symbol?
    if [ ! -z "$FINDING" ]; then
        explode "$TARGET" $LINE "$MARK" "Inappropriate symbol for use of trademark \"$MARK\""
        exit 1
    fi
done
