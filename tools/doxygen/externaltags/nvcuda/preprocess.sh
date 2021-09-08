#!/usr/bin/env bash

# Preprocess the API header to match NVIDIA's nonstandard Doxygen hashing :D

# CUDA include directory...
CUDA_INC_DIR="$1"
shift

for F in "$@" ; do
    cp "$CUDA_INC_DIR/$(basename "$F")" "$F"
done

# Iterate over the CUDA API functions (BECAUSE THIS SEEMS FAST)
for F in "$@" ; do
    for i in $(cat "$CUDA_INC_DIR/$(basename "$F")" | grep "extern " | grep cuda | sed -Ee 's/.+ ([a-zA-Z0-9]+)\(.+?/\1/'); do
        # Is this part of the host runtime API?
        if grep -q $i "$CUDA_INC_DIR/cuda_device_runtime_api.h"; then
            # Add the __device__ specifier to it.
            sed -i -Ee 's/__host__ (.*'$i'.*)/__host__ __device__ \1/;s/__device__ __device__/__device__/g' "$F"
        fi
    done
    sed -i -Ee 's/__device_builtin__//g' "$F"
done
