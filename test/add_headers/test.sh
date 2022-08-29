#!/bin/bash

set -e

# Arguments that are common between test scripts.
XCMAKE_DIR="$1"
TMP_DIR="$2"
shift 2

# Windows stupidity.
if uname | fgrep MINGW ; then
    WINDOWS=1
    CMAKE_ARGS+=(-G"NMake Makefiles")
    MAKE=("nmake")
else
    MAKE=("make")
fi

# Test all the examples.
cd add_headers
for D in $(find -mindepth 1 -maxdepth 1 -type d) ; do
    if [ ! -e "${D}/CMakeLists.txt" ] ; then
        continue
    fi
    echo -e "\e[33;1mTesting headers\e[m: \e[1m${D}\e[m"

    # Change to the build directory for this test.
    mkdir -p "${TMP_DIR}/${D}"
    cd "${TMP_DIR}/${D}"

    # Allow errors so we can report them.
    set +e

    # Configure.
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="install" \
        -DCMAKE_PREFIX_PATH="${XCMAKE_DIR}/../" \
        "${CMAKE_ARGS[@]}" \
        "${XCMAKE_DIR}/test/add_headers/${D}"
    if [ "$?" != "0" ] ; then
        echo -e "\e[31;1mError\e[m: cmake configure failed" 1>&2
        exit 1
    fi

    # Run make.
    MAKE_OUTPUT="$("${MAKE[@]}" install VERBOSE=1 2>&1)"
    E="$?"
    echo "${MAKE_OUTPUT}"

    if [ "$E" != "0" ] ; then
        echo -e "\e[31;1mError\e[m: make failed" 1>&2
        exit 1
    fi

    # No more errors.
    set -e

    # Compare the directorie.
    if ! diff -y "${XCMAKE_DIR}/test/add_headers/${D}/ref" "install/include" ; then
        echo -e "\e[31;1mError\e[m: compare failed" 1>&2
        exit 1
    fi

    # We're done with this directory.
    cd -
done
