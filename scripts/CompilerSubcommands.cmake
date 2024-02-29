# Find the linker the compiler uses to link CUDA fat binaries
# DST - The name of the variable to store the result into.
# ARCH - The GPU architecture to test.
function(getCudaFatbinLinker DST ARCH)
    string(SUBSTRING "${ARCH}" 0 3 PREFIX)
    if ("${PREFIX}" STREQUAL "sm_")
        find_package(CUDAToolkit 8.0 REQUIRED)
        set(cudaPath "${CUDAToolkit_BIN_DIR}/../")
    else()
        find_package(redscale REQUIRED)
        set(cudaPath "${redscale_TOOLKIT_ROOT_DIR}")
    endif()

    execute_process(COMMAND ${CMAKE_COMMAND} -E echo
                    COMMAND ${CMAKE_CXX_COMPILER} --cuda-path=${cudaPath} --cuda-gpu-arch=${ARCH} -x cuda -c - "-###"
                    RESULT_VARIABLE clangDiscoveryRet
                    ERROR_VARIABLE clangDiscoveryStderr)
    if (NOT "${clangDiscoveryRet}" STREQUAL "0")
        message(FATAL_ERROR "Could not run Clang to find fatbin linker")
    endif()

    string(REGEX MATCH "[^\n]+\"-o\" \"[^\"]*\.fatbin\"" lldLine "${clangDiscoveryStderr}")
    string(REGEX REPLACE "^ \"([^\"]+)\".*" "\\1" dst "${lldLine}")
    if("${dst}" STREQUAL "")
        message(FATAL_ERROR "Could not find CUDA fatbin linker")
    else()
        message("Found CUDA fatbin linker for ${ARCH}: ${dst}")
    endif()

    set(${DST} "${dst}" PARENT_SCOPE)
endfunction()
