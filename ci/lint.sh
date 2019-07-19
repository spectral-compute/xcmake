#!/usr/bin/env bash

RC=0
for i in $(find $1 -name \*.cmake -o -name CMakeLists.txt); do
    if ! cmakelint --filter=-whitespace/extra,-linelength --spaces=4 "$i"; then
        RC=1
    fi
done

exit $RC
