#!/bin/bash

# Default arguments.
XCMAKE_DIR="$(realpath "$(dirname "$0")/..")"

# This script should run from the test directory.
cd "${XCMAKE_DIR}/test"

# Parse arguments.
ARGS=("$@")
TEST_FILTER=".*"
while [ "$#" != "0" ] ; do
    ARG="$1"
    shift
    case "${ARG}" in
        -c|--toolchain-base-dir)
            shift
        ;;
        -f)
            TEST_FILTER="$1"
            shift
        ;;
        -k)
            KEEP_TMP=1
        ;;
        *)
            echo -e "\e[31;1mUnknown argument\e[m: ${ARG}" 1>&2
            exit 1
        ;;
    esac
done

# Create a temporary directory.
TMP_DIR="$(mktemp -d -t XCMAKE_TEST.XXXXXXXX)"

# Run all the tests.
SUCCESS_TESTS=()
FAIL_TESTS=()
for D in $(find -mindepth 1 -type d) ; do
    # Only matching tests should run.
    if ! echo "${D}" | grep -q -E "${TEST_FILTER}" ; then
        continue
    fi

    # Only directories with a test script should be run.
    if [ ! -e "${D}/test.sh" ] ; then
        continue
    fi

    # Run the test, and record the pass/fail result.
    echo -e "\e[35;1mRunning test\e[m: \e[1m${D:2}\e[m"
    if "${D}/test.sh" "${XCMAKE_DIR}" "${TMP_DIR}/${D:2}" "${ARGS[@]}" ; then
        echo -e "\e[32;1mPassed\e[m"
        SUCCESS_TESTS+=("${D:2}")
    else
        echo -e "\e[31;1mFailed\e[m"
        FAIL_TESTS+=("${D:2}")
    fi
    echo
done

# Print summary.
echo -e "\e[35;1mSummary\e[m"
for T in "${SUCCESS_TESTS[@]}" ; do
    echo -e "\e[32;1mPassed\e[m: \e[1m${T}\e[m"
done
for T in "${FAIL_TESTS[@]}" ; do
    echo -e "\e[31;1mFailed\e[m: \e[1m${T}\e[m"
    FAIL=1
done

# Delete the temporary directory.
if [ "${KEEP_TMP}" == "1" ] ; then
    echo -e "Keeping \e[1m${TMP_DIR}\e[m"
else
    rm -rf "${TMP_DIR}"
fi

# Failure?
if [ ! -z "${FAIL}" ] ; then
    exit 1
fi
