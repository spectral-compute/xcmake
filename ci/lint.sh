#!/usr/bin/env bash

cmakelint --filter=-whitespace/extra,-linelength,-convention/filename,-package/stdargs --spaces=4 \
    $(find $1 -name \*.cmake -o -name CMakeLists.txt)
