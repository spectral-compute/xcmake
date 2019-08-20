#!/usr/bin/env bash

# A script to sanitise files for trademark compliance.

# Applies the following rules to the input file:
# - The first use of the mark must be immediately followed by the symbol.
# - The first use of the mark must be immediately preceded by the owner.
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

    # The symbol identifying the type of mark
    SYMBOL=$(echo "$TM" | sed -Ee 's/.*([™®]).*/\1/g')

    # The mark itself.
    MARK=$(echo "$TM" | cut -d ' ' -f 2- | sed -Ee 's/[™®]//g')

    FIRST=$(cat "$TARGET" | grep -n "$MARK" | head -n 1)

    # If the trademark isn't found, skip it.
    if [ "$FIRST" == "" ]; then
        continue;
    fi

    LINE=$(echo $FIRST | cut -d ':' -f 1)

    # Has the symbol?
    if ! echo "$FIRST" | grep -q "$MARK$SYMBOL"; then
        explode "$TARGET" $LINE "$MARK" "Missing $SYMBOL for first use of trademark \"$MARK\""
        exit 1
    fi

    # Has the owner name?
    if [ "$OWNER" != "" ]; then
        if ! echo "$FIRST" | grep -Eq "$OWNER[™®]? $MARK"; then
            explode "$TARGET" $LINE "$MARK" "Missing trademark attribution (\"$OWNER\") for first use of \"$MARK\""
            exit 1
        fi
    fi
done
