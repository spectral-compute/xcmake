# The compute capabilities to target, as a cmake list.
default_value(CUDA_COMPUTE_CAPABILITIES "30")

# Add some CUDA source files to an existing executable or library target.
function(add_cuda TARGET)
    find_package(CUDA 8.0 REQUIRED)

    set(OBJ_TARGET_NAME ${TARGET}_cuda_objects)

    # Even though cmake ostensibly supports CUDA, we don't want it to try to be helpful
    # on this one - otherwise it starts doing unhelpful things with nvcc...
    set_source_files_properties(${ARGN} PROPERTIES LANGUAGE CXX)

    # If we've been here before, all we have to do is add the new source files and we're done.
    if (TARGET ${OBJ_TARGET_NAME})
        target_sources(${OBJ_TARGET_NAME} PRIVATE ${ARGN})
        target_sources(${TARGET} PRIVATE $<TARGET_OBJECTS:${OBJ_TARGET_NAME}>)
        return()
    endif()

    # Compiler flags for cuda compilation on clang.
    set(CUDA_CLANG_FLAGS
        -x cuda
        --cuda-path=${CUDA_TOOLKIT_ROOT_DIR}
        -fcuda-flush-denormals-to-zero

        # The various PTX versions that were requested...
        --cuda-gpu-arch=sm_$<JOIN:${CUDA_COMPUTE_CAPABILITIES}, --cuda-gpu-arch=sm_>
    )

    # Firstly, add CUDA to the primary target.
    target_include_directories(${TARGET} PRIVATE ${CUDA_INCLUDE_DIRS})
    target_compile_options(${TARGET} PRIVATE ${CUDA_CLANG_FLAGS})

    # According to the cmake manual, static cudart is not viable on Mac.
    if (APPLE)
        # This is just the dynamic cudart library, ostensibly...
        target_link_libraries(${TARGET} PRIVATE ${CUDA_LIBRARIES})
    else ()
        target_link_libraries(${TARGET} PRIVATE ${CUDA_cudart_static_LIBRARY})
    endif ()

    # Now let's set up the object target...
    add_library(${OBJ_TARGET_NAME} OBJECT ${ARGN})
    target_compile_options(
        ${OBJ_TARGET_NAME} PRIVATE ${CUDA_CLANG_FLAGS}
    )

    # Hook up the object target to the client target.
    target_sources(${TARGET} PRIVATE $<TARGET_OBJECTS:${OBJ_TARGET_NAME}>)

    # Copy across include directories, dependencies, and so on. The practical effect is that the
    # code in the CUDA files behaves as if it's part of the other target (with respect to what
    # it's able to reference, anyway).
    target_include_directories(${OBJ_TARGET_NAME} PRIVATE
        $<TARGET_PROPERTY:${TARGET},INCLUDE_DIRECTORIES>
        $<TARGET_PROPERTY:${TARGET},INTERFACE_INCLUDE_DIRECTORIES>
    )
    target_include_directories(${OBJ_TARGET_NAME} SYSTEM PRIVATE
        $<TARGET_PROPERTY:${TARGET},INTERFACE_SYSTEM_INCLUDE_DIRECTORIES>
    )
    target_compile_definitions(${OBJ_TARGET_NAME} PRIVATE
        $<TARGET_PROPERTY:${TARGET},COMPILE_DEFINITIONS>
    )

    # Wait for completion of direct link dependencies, and manually-added dependencies. This is a
    # touch overkill, but it can avoid some annoying edgecases with externalproject build ordering.
    get_target_property(WAIT_FOR ${TARGET} LINK_LIBRARIES)
    get_target_property(WAIT_MORE_FOR ${TARGET} MANUALLY_ADDED_DEPENDENCIES)

    # Delete "-NOTFOUND" sillies.
    if (NOT WAIT_MORE_FOR)
        set(WAIT_MORE_FOR "")
    endif()
    if (NOT WAIT_FOR)
        set(WAIT_FOR "")
    endif()

    # Strip generator expressions..
    string(GENEX_STRIP "${WAIT_MORE_FOR}" WAIT_MORE_FOR)
    string(GENEX_STRIP "${WAIT_FOR}" WAIT_FOR)

    # Make the object target await the completion of all link dependencies.
    foreach (_DEP IN LISTS WAIT_FOR WAIT_MORE_FOR)
        if (TARGET ${_DEP})
            add_dependencies(${OBJ_TARGET_NAME} ${_DEP})
        endif()
    endforeach ()
endfunction()
