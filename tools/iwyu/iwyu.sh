#!/usr/bin/env bash

MAPFILE=$(dirname "$0")/all.imp
IWYU="include-what-you-use -Xiwyu --mapping_file=$MAPFILE"

# Some additional magic is needed to make iwyu work correctly with CUDA.
if echo "$@" | grep -- "-x cuda"; then
    # Run it on host and device code separately
    $IWYU --cuda-host-only "$@"
    $IWYU --cuda-device-only "$@"
else
    # Just run it
    $IWYU "$@"
fi
