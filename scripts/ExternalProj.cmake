### A more elaborate ExternalProject module that provides imported targets.
include(ExternalProject)

# Path to which external projects get installed in the build tree.
set(EP_INSTALL_DIR "${CMAKE_BINARY_DIR}/external_projects" CACHE INTERNAL "")

function(AddExternalProject TARGET)
    # Escape early if we already defined this TARGET
    if(TARGET ${TARGET})
        return()
    endif()

    # Parse the function arguments. These are split into three categories:
    # - Arguments added in XCMake which dictate libraries or executables to be created and marked dependent on TARGET
    # - Arguments we just want to delete, because this function sets them automatically
    # - Built-in arguments we want as variables within this function
    set(flags)
    set(oneValueArgs
        # Custom
        CMAKE

        # Built-in
        GIT_REPOSITORY

        # Delete
        BINARY_DIR
        SOURCE_DIR
        INSTALL_DIR
        EXCLUDE_FROM_ALL
    )
    set(multiValueArgs
        # Custom
        STATIC_LIBRARIES
        DYNAMIC_LIBRARIES
        EXECUTABLES

        # Built-in
        CMAKE_ARGS
        BUILD_BYPRODUCTS
    )
    cmake_parse_arguments("ep" "${flags}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

    # Construct the list of arguments to just forward directly to ExternalProject_Add. We start with
    # all the arguments not consumed by `cmake_parse_arguments`
    set(EXTRA_ARGS "${ep_UNPARSED_ARGUMENTS}")

    # Set or override some of the CMake arguments, if it's a CMake build system
    if (ep_CMAKE OR ep_CMAKE_ARGS)
        # This is needed if we want to allow no CMAKE_ARGS in the function call
        if (NOT ep_CMAKE_ARGS)
            set(ep_CMAKE_ARGS)
        endif ()
        list(APPEND ep_CMAKE_ARGS
             -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
             -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
             -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
             -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
             -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
             -DCMAKE_LINKER=${CMAKE_LINKER}
        )
    endif ()

    # If it's a git-source set UPDATE_COMMAND to "", and re-add the GIT_REPOSITORY command we consumed
    if (ep_GIT_REPOSITORY)
        list(APPEND EXTRA_ARGS
            UPDATE_COMMAND
            GIT_REPOSITORY
            ${ep_GIT_REPOSITORY}
        )
    endif ()

    # Add our amended CMAKE_ARGS to EXTRA_ARGS to be passed along
    list(APPEND EXTRA_ARGS
        CMAKE_ARGS
        ${ep_CMAKE_ARGS}
    )

    # Workaround for cmake being stupid and not allowing nonexistent include directories.
    file(MAKE_DIRECTORY ${EP_INSTALL_DIR}/include)

    # Loop over our custom function arguments
    # - Add library/executable targets as specified
    # - Set IMPORTED_LOCATION property on those targets
    # - Include directories for those targets. The script calling this one has to do it themselves if the includes are more complicated than this.
    # - Add install instructions for some of those functions. NOTE - These instructions are for installation of the
    #     top-level project, NOT for the external project's own install step.
    foreach (_LIB ${ep_STATIC_LIBRARIES})
        add_library(${_LIB} STATIC IMPORTED GLOBAL)

        set(SLIB_PATH ${EP_INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}${_LIB}${CMAKE_STATIC_LIBRARY_SUFFIX})
        list(APPEND ep_BUILD_BYPRODUCTS ${SLIB_PATH})
        set_target_properties(${_LIB} PROPERTIES
            IMPORTED_LOCATION ${SLIB_PATH}
        )

        target_include_directories(${_LIB} INTERFACE ${EP_INSTALL_DIR}/include)

        get_target_property(v1 ${_LIB} IMPORTED_LOCATION)
    endforeach ()

    foreach (_LIB ${ep_DYNAMIC_LIBRARIES})
        add_library(${_LIB} SHARED IMPORTED GLOBAL)

        set(DLIB_PATH ${EP_INSTALL_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}${_LIB}${CMAKE_SHARED_LIBRARY_SUFFIX})
        list(APPEND ep_BUILD_BYPRODUCTS ${DLIB_PATH})
        set_target_properties(${_LIB} PROPERTIES
            IMPORTED_LOCATION ${DLIB_PATH}
            IMPORTED_IMPLIB ${EP_INSTALL_DIR}/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}${_LIB}${CMAKE_IMPORT_LIBRARY_SUFFIX}
        )

        target_include_directories(${_LIB} INTERFACE ${EP_INSTALL_DIR}/include)

        install(FILES ${DLIB_PATH} DESTINATION ./lib/)
    endforeach ()

    foreach (_EXE ${ep_EXECUTABLES})
        add_executable(${_EXE} STATIC IMPORTED GLOBAL)

        set(EXE_PATH ${EP_INSTALL_DIR}/bin/${_EXE}${CMAKE_EXECUTABLE_SUFFIX})
        list(APPEND ep_BUILD_BYPRODUCTS ${EXE_PATH})
        set_target_properties(${_EXE} PROPERTIES
            IMPORTED_LOCATION ${EXE_PATH}
        )

        install(PROGRAMS ${EXE_PATH} DESTINATION ./bin/)
    endforeach ()

    ExternalProject_Add(
        ${TARGET}
        EXCLUDE_FROM_ALL 1
        BINARY_DIR ${TARGET}-obj
        SOURCE_DIR ${TARGET}
        INSTALL_DIR ${EP_INSTALL_DIR}
        BUILD_BYPRODUCTS ${ep_BUILD_BYPRODUCTS}

        # Forward all the other arguments, suitably fiddled-with.
        ${EXTRA_ARGS}
    )

    # Configure the exported targets...
    foreach (_LIB ${ep_STATIC_LIBRARIES})
        add_dependencies(${_LIB} ${TARGET})
    endforeach ()

    foreach (_LIB ${ep_DYNAMIC_LIBRARIES})
        add_dependencies(${_LIB} ${TARGET})
    endforeach ()

    foreach (_EXE ${ep_EXECUTABLES})
        add_dependencies(${_EXE} ${TARGET})
    endforeach ()
endfunction()
