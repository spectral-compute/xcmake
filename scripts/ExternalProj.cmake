include_guard()

### A more elaborate ExternalProject module that provides imported targets.
include(ExternalProject)

# Path to which external projects get installed in the build tree.
set(EP_ROOT_DIR "${CMAKE_BINARY_DIR}/external_projects" CACHE INTERNAL "")
set(EP_INSTALL_DIR "${EP_ROOT_DIR}/inst" CACHE INTERNAL "")

# Extra CFLAGS/CXXFLAGS for external projects
set(XCMAKE_EP_CXX_FLAGS "")
set(XCMAKE_EP_C_FLAGS "")
set(XCMAKE_EP_LINKER_FLAGS "")
set(XCMAKE_EP_CMAKE_ARGS "")

if(WIN32)
    if(CMAKE_CXX_COMPILER_ID MATCHES MSVC)
    else()
        # EPs will likely expect clang to be behaving as it normally does on Windows.
        # If the EP's own build system turns this off, that'll take precedence anyway, so this should be the
        # arrangement that's least likely to explode.
        list(APPEND XCMAKE_EP_CXX_FLAGS "-fms-compatibility")
        list(APPEND XCMAKE_EP_C_FLAGS "-fms-compatibility")
    endif()

    # Propagate the default runtime selection.
    set(_MSVC_RUNTIME_LIBRARY_TYPE "MultiThreaded")
    if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        set(_MSVC_RUNTIME_LIBRARY_TYPE "${_MSVC_RUNTIME_LIBRARY_TYPE}Debug")
    endif()
    if (NOT XCMAKE_STATIC_STDCXXLIB)
        set(_MSVC_RUNTIME_LIBRARY_TYPE "${_MSVC_RUNTIME_LIBRARY_TYPE}DLL")
    endif()
    list(APPEND XCMAKE_EP_CMAKE_ARGS "-DCMAKE_POLICY_DEFAULT_CMP0091=NEW"
                                     "-DCMAKE_MSVC_RUNTIME_LIBRARY=${_MSVC_RUNTIME_LIBRARY_TYPE}")
else()
    # Propagate the default C++ standard library staticness.
    if (XCMAKE_STATIC_STDCXXLIB)
        # Unfortunately, I see no way ot make this get added only to C++ targets.
        list(APPEND XCMAKE_EP_LINKER_FLAGS "-static-libstdc++")
    endif()
endif()

# Propagate libc++, if it's being used as the default.
if (XCMAKE_LIBCXX)
    list(APPEND XCMAKE_EP_CXX_FLAGS "-stdlib=libc++")
    list(APPEND XCMAKE_EP_LINKER_FLAGS "-stdlib=libc++")
endif()

# Dependent libraries need to be built with msan, too
if (XCMAKE_SANITISER STREQUAL "Memory")
    list(APPEND XCMAKE_EP_CXX_FLAGS "-fsanitize=memory" -fsanitize-memory-track-origins=2)
    list(APPEND XCMAKE_EP_C_FLAGS "-fsanitize=memory" -fsanitize-memory-track-origins=2)
    list(APPEND XCMAKE_EP_LINKER_FLAGS "-fsanitize=memory" -fsanitize-memory-track-origins=2)
endif()

# Pass in the toolchain's arguments.
if (XCMAKE_TOOLCHAIN_DIR)
    list(APPEND XCMAKE_EP_CMAKE_ARGS "-DXCMAKE_TOOLCHAIN_DIR=${XCMAKE_TOOLCHAIN_DIR}")
endif()
if (XCMAKE_TRIBBLE)
    list(APPEND XCMAKE_EP_CMAKE_ARGS "-DXCMAKE_TRIBBLE=${XCMAKE_TRIBBLE}")
endif()
if (XCMAKE_TRIPLE_VENDOR)
    list(APPEND XCMAKE_EP_CMAKE_ARGS "-DXCMAKE_TRIPLE_VENDOR=${XCMAKE_TRIPLE_VENDOR}")
endif()

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
        INSTALL_DIR
        EXCLUDE_FROM_ALL
    )
    set(multiValueArgs
        # Custom
        C_FLAGS # Only used by supported build systems (CMake). Support for others may be added in the future.
        CXX_FLAGS # Only used by supported build systems (CMake). Support for others may be added in the future.
        LIBRARIES
        SHARED_LIBRARIES
        STATIC_LIBRARIES
        HEADER_LIBRARIES
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
    if(ep_CMAKE OR ep_CMAKE_ARGS)
        string(JOIN " " CXX_FLAGS ${XCMAKE_EP_CXX_FLAGS} ${ep_CXX_FLAGS})
        string(JOIN " " C_FLAGS ${XCMAKE_EP_C_FLAGS} ${ep_C_FLAGS})
        string(JOIN " " LINKER_FLAGS ${XCMAKE_EP_LINKER_FLAGS})

        list(APPEND CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
            -DCMAKE_INSTALL_LIBDIR:PATH=${CMAKE_INSTALL_LIBDIR}
            -DCMAKE_INSTALL_BINDIR:PATH=${CMAKE_INSTALL_BINDIR}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            -DCMAKE_LINKER=${CMAKE_LINKER}
            -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
            "-DCMAKE_CXX_FLAGS=${CXX_FLAGS}"
            "-DCMAKE_C_FLAGS=${C_FLAGS}"
            "-DCMAKE_EXE_LINKER_FLAGS=${LINKER_FLAGS}"
            "-DCMAKE_SHARED_LINKER_FLAGS=${LINKER_FLAGS}"

            # Avoid install-time logspam
            -DCMAKE_INSTALL_MESSAGE=NEVER

            ${XCMAKE_EP_CMAKE_ARGS}
            ${ep_CMAKE_ARGS}
        )
    endif()

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
        add_library(${_LIB} STATIC IMPORTED NOINSTALL GLOBAL)

        set(SLIB_PATH ${EP_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${_LIB}${CMAKE_STATIC_LIBRARY_SUFFIX})
        list(APPEND ep_BUILD_BYPRODUCTS ${SLIB_PATH})
        set_target_properties(${_LIB} PROPERTIES
            IMPORTED_LOCATION ${SLIB_PATH}
        )

        target_include_directories(${_LIB} INTERFACE ${EP_INSTALL_DIR}/include)
    endforeach ()

    foreach (_LIB ${ep_SHARED_LIBRARIES})
        add_library(${_LIB} SHARED IMPORTED NOINSTALL GLOBAL)

        # Only put IMPLIB data in place on platforms which need it to avoid polluting the build and expecting files that won't exist
        # The two DLIB paths differ in that non-implib platforms send their shared library to /lib, and implib platforms send the
        # library to /bin and the implib to /lib
        if(NOT XCMAKE_IMPLIB_PLATFORM)
            set(DLIB_PATH ${EP_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}/${CMAKE_SHARED_LIBRARY_PREFIX}${_LIB}${CMAKE_SHARED_LIBRARY_SUFFIX})

            set_target_properties(${_LIB} PROPERTIES
                IMPORTED_LOCATION ${DLIB_PATH}
            )
        else()
            set(DLIB_PATH ${EP_INSTALL_DIR}/${CMAKE_INSTALL_BINDIR}/${CMAKE_SHARED_LIBRARY_PREFIX}${_LIB}${CMAKE_SHARED_LIBRARY_SUFFIX})
            set(IMPLIB_PATH ${EP_INSTALL_DIR}/${CMAKE_INSTALL_LIBDIR}/${CMAKE_IMPORT_LIBRARY_PREFIX}${_LIB}${CMAKE_IMPORT_LIBRARY_SUFFIX})

            set_target_properties(${_LIB} PROPERTIES
                IMPORTED_LOCATION ${DLIB_PATH}
                IMPORTED_IMPLIB ${IMPLIB_PATH}
            )

            list(APPEND ep_BUILD_BYPRODUCTS ${IMPLIB_PATH})
        endif()

        list(APPEND ep_BUILD_BYPRODUCTS ${DLIB_PATH})

        target_include_directories(${_LIB} INTERFACE ${EP_INSTALL_DIR}/include)
    endforeach ()

    foreach (_HL ${ep_HEADER_LIBRARIES})
        add_library(${_HL} INTERFACE IMPORTED NOINSTALL GLOBAL)
        add_dependencies(${_HL} ${TARGET})
        target_include_directories(${_HL} INTERFACE ${EP_INSTALL_DIR}/include)
    endforeach()

    foreach (_EXE ${ep_EXECUTABLES})
        add_executable(${_EXE} STATIC IMPORTED NOINSTALL GLOBAL)

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
