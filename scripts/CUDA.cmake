function(add_cuda_to_target TARGET)
    if ("${XCMAKE_GPU_TYPE}" STREQUAL "amd")
    elseif ("${XCMAKE_GPU_TYPE}" STREQUAL "nvidia")
    elseif ("${XCMAKE_GPU_TYPE}" STREQUAL "")
        message(FATAL_ERROR "You didn't specify any GPU targets with -DXCMAKE_GPUS!")
    else ()
        message(FATAL_ERROR "Unknown GPU type: ${XCMAKE_GPU_TYPE}")
    endif ()

    set_target_properties(${TARGET} PROPERTIES CUDA ON)
endfunction()

# Add an executable that uses CUDA.
function(add_cuda_executable TARGET)
    add_executable(${TARGET} ${ARGN})
    add_cuda_to_target(${TARGET})
endfunction()

# Add a library that uses CUDA.
function(add_cuda_library TARGET)
    add_library(${TARGET} ${ARGN})
    add_cuda_to_target(${TARGET})
endfunction()
