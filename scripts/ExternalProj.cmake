include_guard()

### A more elaborate ExternalProject module that provides imported targets.
include(ExternalProject)

# Path to which external projects get installed in the build tree.
set(EP_ROOT_DIR "${CMAKE_BINARY_DIR}/external_projects" CACHE INTERNAL "")
set(EP_INSTALL_DIR "${EP_ROOT_DIR}/inst" CACHE INTERNAL "")

function(add_external_project TARGET)
    # Parse the function arguments. These are split into three categories:
    # - Arguments added in XCMake which dictate libraries or executables to be created and marked dependent on TARGET
    # - Arguments we just want to delete, because this function sets them automatically
    # - Built-in arguments we want as variables within this function
    set(flags
        # Custom
        CMAKE # Allows a CMAKE EP to be declared with no additional CMAKE arguments
    )
    set(oneValueArgs
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
        LIBRARIES
        SHARED_LIBRARIES
        STATIC_LIBRARIES
        EXECUTABLES

        # Built-in
        CMAKE_ARGS
        BUILD_BYPRODUCTS
    )
    cmake_parse_arguments("ep" "${flags}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

    # Send the LIBRARIES list to create the right type of targets
    if(ep_LIBRARIES AND ${BUILD_SHARED_LIBS})
        list(APPEND ep_SHARED_LIBRARIES ${ep_LIBRARIES})
    elseif(ep_LIBRARIES)
        list(APPEND ep_STATIC_LIBRARIES ${ep_LIBRARIES})
    endif()

    # Construct the list of arguments to just forward directly to ExternalProject_Add. We start with
    # all the arguments not consumed by `cmake_parse_arguments`
    set(EXTRA_ARGS "${ep_UNPARSED_ARGUMENTS}")

    # Set or override some of the CMake arguments, if it's a CMake build system
    set(CMAKE_ARGS "")
    if (ep_CMAKE OR ep_CMAKE_ARGS)
        list(APPEND CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            -DCMAKE_LINKER=${CMAKE_LINKER}
            -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}

            # Avoid install-time logspam
            -DCMAKE_INSTALL_MESSAGE=NEVER

            ${ep_CMAKE_ARGS}
        )
    endif ()

    # Add our amended CMAKE_ARGS to EXTRA_ARGS to be passed along
    list(APPEND EXTRA_ARGS
        CMAKE_ARGS
        ${CMAKE_ARGS}
    )

    # If it's a git-source set UPDATE_COMMAND to "", and re-add the GIT_REPOSITORY argument we consumed
    if (ep_GIT_REPOSITORY)
        list(APPEND EXTRA_ARGS
            # Re-add the GIT_REPOSITORY arg we consumed above.
            GIT_REPOSITORY ${ep_GIT_REPOSITORY}

            # Tell git to use parallel submodule fetching to speed things up.
            GIT_CONFIG submodule.fetchJobs=5
        )

        # Default to not having an update command at all.
        set(EXTRA_ARGS "${EXTRA_ARGS};UPDATE_COMMAND;;")
    endif ()

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

        set(SLIB_PATH ${EP_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${_LIB}${CMAKE_STATIC_LIBRARY_SUFFIX})
        list(APPEND ep_BUILD_BYPRODUCTS ${SLIB_PATH})
        set_target_properties(${_LIB} PROPERTIES
            IMPORTED_LOCATION ${SLIB_PATH}
        )

        target_include_directories(${_LIB} INTERFACE ${EP_INSTALL_DIR}/include)
    endforeach ()

    foreach (_LIB ${ep_SHARED_LIBRARIES})
        add_library(${_LIB} SHARED IMPORTED GLOBAL)

        # Since we're just referring to a file here, cmake can't make this distinction for us so we have to hand-hold.
        if (WIN32)
            set(INSTALL_DIR ${CMAKE_INSTALL_BINDIR})
        else()
            set(INSTALL_DIR ${CMAKE_INSTALL_LIBDIR})
        endif()

        set(DLIB_PATH ${EP_INSTALL_DIR}/${INSTALL_DIR}/${CMAKE_SHARED_LIBRARY_PREFIX}${_LIB}${CMAKE_SHARED_LIBRARY_SUFFIX})
        set(IMPLIB_PATH ${EP_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}/${CMAKE_IMPORT_LIBRARY_PREFIX}${_LIB}${CMAKE_IMPORT_LIBRARY_SUFFIX})
        list(APPEND ep_BUILD_BYPRODUCTS ${DLIB_PATH} ${IMPLIB_PATH})
        set_target_properties(${_LIB} PROPERTIES
            IMPORTED_LOCATION ${DLIB_PATH}
            IMPORTED_IMPLIB ${IMPLIB_PATH}
        )

        target_include_directories(${_LIB} INTERFACE ${EP_INSTALL_DIR}/include)
    endforeach ()

    foreach (_EXE ${ep_EXECUTABLES})
        add_executable(${_EXE} STATIC IMPORTED GLOBAL)

        set(EXE_PATH ${EP_INSTALL_DIR}/${CMAKE_INSTALL_BINDIR}/${_EXE}${CMAKE_EXECUTABLE_SUFFIX})
        list(APPEND ep_BUILD_BYPRODUCTS ${EXE_PATH})
        set_target_properties(${_EXE} PROPERTIES
            IMPORTED_LOCATION ${EXE_PATH}
        )
    endforeach ()

    externalproject_add(
        ${TARGET}
        EXCLUDE_FROM_ALL 1
        PREFIX ${EP_ROOT_DIR}/${TARGET}
        STAMP_DIR ${EP_ROOT_DIR}/stamps
        INSTALL_DIR ${EP_INSTALL_DIR}
        BUILD_BYPRODUCTS ${ep_BUILD_BYPRODUCTS}

        # Forward all the other arguments, suitably fiddled-with.
        "${EXTRA_ARGS}"
    )

    # Configure the exported targets...
    foreach (_ARTEFACT IN LISTS ep_STATIC_LIBRARIES ep_SHARED_LIBRARIES ep_EXECUTABLES)
        add_dependencies(${_ARTEFACT} ${TARGET})
        install(TARGETS ${_ARTEFACT} EP_TARGET)
    endforeach ()
endfunction()

# Get the path to the stamp file representing the completion of the build for the given IMPORTED target.
function(get_final_stamp_path OUTVAR TARGET)
    get_target_property(MAN_DEPS ${TARGET} MANUALLY_ADDED_DEPENDENCIES)

    foreach (DEP ${MAN_DEPS})
        # Is this an external project?
        if (IS_DIRECTORY "${EP_ROOT_DIR}/${DEP}")
            # It is, so now we can determine the name of the install stampfile.
            set(${OUTVAR} "${EP_ROOT_DIR}/stamps/${DEP}-install" PARENT_SCOPE)
            return()
        endif()
    endforeach()

    message(FATAL_ERROR "Failed to compute stampfile path for ${TARGET}")
endfunction()
