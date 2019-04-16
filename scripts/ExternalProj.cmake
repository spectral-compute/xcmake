### A more elaborate ExternalProject module that provides imported targets.
include(ExternalProject)

# Path to which external projects get installed in the build tree.
set(EP_INSTALL_DIR "${CMAKE_BINARY_DIR}/external_projects" CACHE INTERNAL "")

function(AddExternalProject TARGET)
    # Parse our extra parameters.
    set(flags)
    set(oneValueArgs
        # Built-in ones we watch for.
        GIT_REPOSITORY

        # Arguments we just want to delete.
        BINARY_DIR
        SOURCE_DIR
        INSTALL_DIR
        EXCLUDE_FROM_ALL
    )
    set(multiValueArgs
        # Extra ones we added...
        STATIC_LIBRARIES
        DYNAMIC_LIBRARIES
        EXECUTABLES

        # Built-in ones we watch for.
        CMAKE_ARGS
    )
    cmake_parse_arguments("ep" "${flags}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

    # Construct the list of arguments to just forward directly to ExternalProject_Add. We start with
    # all the arguments not consumed by `cmake_parse_arguments`
    set(EXTRA_ARGS "${es_UNPARSED_ARGUMENTS}")

    # Arg-parse again: this time looking for specific built-in arguments so we can set default behaviours.

    # A convenience: if it's a git-source, don't have an update command.
    if (ep_GIT_REPOSITORY)
        # Add `UPDATE_COMMAND ""`, the hard way, and re-insert the GIT_REPOSITORY argument we consumed.
        list(APPEND EXTRA_ARGS CMAKE_ARGS "${ep_CMAKE_ARGS}")
        set(EXTRA_ARGS "${EXTRA_ARGS};UPDATE_COMMAND;;GIT_REPOSITORY;${ep_GIT_REPOSITORY}")
    endif ()

    # If it's a cmake buildsystem, sort out some of the cmake arguments ourselves.
    if (ep_CMAKE_ARGS)
        list(APPEND ep_CMAKE_ARGS
             -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
             -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
             -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        )
        list(APPEND EXTRA_ARGS CMAKE_ARGS "${ep_CMAKE_ARGS}")
    endif ()

    ExternalProject_Add(
        ${TARGET}
        EXCLUDE_FROM_ALL 1
        BINARY_DIR ${TARGET}-obj
        SOURCE_DIR ${TARGET}
        INSTALL_DIR ${EP_INSTALL_DIR}

        # Forward all the other arguments, suitably fiddled-with.
        ${EXTRA_ARGS}
    )

    # Workaround for cmake being stupid and not allowing nonexistent include directories.
    file(MAKE_DIRECTORY ${EP_INSTALL_DIR}/include)

    # Configure the exported targets...
    foreach (_LIB ${ep_STATIC_LIBRARIES})
        add_library(${_LIB} STATIC IMPORTED GLOBAL)

        # If the imported library is requested, actually build it.
        add_dependencies(${_LIB} ${TARGET})

        # Setup the imported target...
        set_target_properties(${_LIB} PROPERTIES
            IMPORTED_LOCATION ${EP_INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}${_LIB}${CMAKE_STATIC_LIBRARY_SUFFIX}
        )

        # Add the include directory. The script calling this one has to do it themselves if the includes are more complicated than this.
        target_include_directories(${_LIB} INTERFACE ${EP_INSTALL_DIR}/include)
    endforeach ()

    foreach (_LIB ${ep_DYNAMIC_LIBRARIES})
        add_library(${_LIB} SHARED IMPORTED GLOBAL)
        add_dependencies(${_LIB} ${TARGET})

        set(LIB_PATH ${EP_INSTALL_DIR}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}${_LIB}${CMAKE_SHARED_LIBRARY_SUFFIX})
        set(IMPLIB_PATH ${EP_INSTALL_DIR}/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}${_LIB}${CMAKE_IMPORT_LIBRARY_SUFFIX})
        set_target_properties(${_LIB} PROPERTIES
            IMPORTED_LOCATION ${LIB_PATH}
            IMPORTED_IMPLIB ${IMPLIB_PATH}
        )

        # Add the include directory. The script calling this one has to do it themselves if the includes are more complicated than this.
        target_include_directories(${_LIB} INTERFACE ${EP_INSTALL_DIR}/include)

        # Install it!
        install(FILES ${LIB_PATH} DESTINATION ./lib/)
    endforeach ()

    foreach (_EXE ${ep_EXECUTABLES})
        add_executable(${_EXE} STATIC IMPORTED GLOBAL)
        add_dependencies(${_EXE} ${TARGET})

        set(EXE_PATH ${EP_INSTALL_DIR}/bin/${_EXE}${CMAKE_EXECUTABLE_SUFFIX})
        set_target_properties(${_EXE} PROPERTIES
            IMPORTED_LOCATION ${EXE_PATH}
        )

        install(PROGRAMS ${EXE_PATH} DESTINATION ./bin/)
    endforeach ()
endfunction()
