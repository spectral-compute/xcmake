#!/bin/bash

set -e

# Arguments that are common between test scripts.
XCMAKE_DIR="$1"
TMP_DIR="$2"
shift 2

# Default arguments.
CMAKE_ARGS=()

# Get arguments out of the environment.
while [ "$#" != "0" ] ; do
    ARG="$1"
    shift
    case "${ARG}" in
        -c|--toolchain-base-dir)
            CMAKE_ARGS+=(-DXCMAKE_TOOLCHAIN_BASE_DIR="$1")
            shift
        ;;
    esac
done

# Windows stupidity.
if uname | fgrep MINGW ; then
    WINDOWS=1
    CMAKE_ARGS+=(-G"NMake Makefiles")
    MAKE=("nmake")
else
    MAKE=("make")
fi

# Test function.
function testTribble {
    TRIBBLE="$1"
    shift

    echo -e "\e[33;1mTesting tribble\e[m: \e[1m${TRIBBLE}\e[m"

    echo -e "\e[34;1mTribble Info\e[m"
    cmake -DXCMAKE_TRIBBLE=${TRIBBLE} -DXCMAKE_SHOW_TRIBBLE=On "${CMAKE_ARGS[@]}" \
          -P "${XCMAKE_DIR}/toolchain/toolchain.cmake"

    echo -e "\e[34;1mBuild simple program\e[m"

    # Change to the build directory for this tribble's test.
    mkdir -p "${TMP_DIR}/${TRIBBLE}"
    cd "${TMP_DIR}/${TRIBBLE}"

    # Allow errors so we can report them.
    set +e

    # Configure.
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="install" \
        -DCMAKE_PREFIX_PATH="${XCMAKE_DIR}/../" \
        -DXCMAKE_TRIBBLE=${TRIBBLE} \
        "${CMAKE_ARGS[@]}" \
        "${XCMAKE_DIR}/test/common/simple"
    if [ "$?" != "0" ] ; then
        echo -e "\e[31;1mError\e[m: cmake configure failed" 1>&2
        return 1
    fi

    # Run make.
    MAKE_OUTPUT="$("${MAKE[@]}" install VERBOSE=1 2>&1)"
    E="$?"
    echo "${MAKE_OUTPUT}"

    if [ "$E" != "0" ] ; then
        echo -e "\e[31;1mError\e[m: make failed" 1>&2
        return 1
    fi

    # No more errors.
    set -e

    # Check the output for the required patterns.
    if [ ! -z "${WINDOWS}" ] ; then
        cd -
        return # Because Windows has a stupid command line length limit, the arguments end up in a file we can't read.
    fi
    while [ "$#" != "0" ] ; do
        if ! echo "${MAKE_OUTPUT}" | grep -qE "$1" ; then
            echo -e "\e[31;1mError\e[m: Compiler output did not match $1" 1>&2
            return 1
        fi
        shift
    done

    # We're done with this directory.
    cd -
}

# Test some tribbles.
testTribble "native" \
            "clang[+][+] .*-march=native" \
            "clang[+][+] .*-mtune=native"


if [ ! -z "${WINDOWS}" ] ; then
    exit # Don't cross compile on Windows, please.
fi

testTribble "ubuntu16.04-aarch64-generic" \
            "clang[+][+] .*--target=aarch64-unknown-linux-gnu" \
            "clang[+][+] .*-mcpu=generic"
testTribble "ubuntu16.04-aarch64-cortexa72" \
            "clang[+][+] .*--target=aarch64-unknown-linux-gnu" \
            "clang[+][+] .*-mcpu=cortex-a72"
