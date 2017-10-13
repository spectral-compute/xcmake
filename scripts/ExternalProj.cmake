### A more elaborate ExternalProject module that provides imported targets.
include(ExternalProject)

# Path to which external projects get installed in the build tree.
set(EP_INSTALL_DIR "${CMAKE_BINARY_DIR}/external_projects" CACHE INTERNAL "")

function(AddExternalProject TARGET)
    set(EXTRA_ARGS "${ARGN}")

    # Wrapper around ExternalProject_Add that provides IMPORTED target generation. The following
    # extra options are provided:
    # - STATIC_LIBRARIES
    # - DYNAMIC_LIBRARIES
    # - EXECUTABLES
    #
    # These describe the outputs of this external project build. IMPORTED targets will be generated
    # with those names, pointing to those artefacts. You can then just `target_link_library()`
    # against those to trigger the actual build of the external project on demand.
    #
    # The BINARY_DIR, SOURCE_DIR, INSTALL_DIR, and EXCLUDE_FROM_ALL parameters of
    # ExternalProject_Add are overridden.
    #
    # Some additional conveniences are provided: cross-compilation flags from this cmake build are
    # propagated (toolchain_file, build_type, compiler). You must provide at least _some_ value for
    # CMAKE_ARGS to exploit this.
    remove_argument(SINGLE EXTRA_ARGS BINARY_DIR)
    remove_argument(SINGLE EXTRA_ARGS SOURCE_DIR)
    remove_argument(SINGLE EXTRA_ARGS INSTALL_DIR)
    remove_argument(SINGLE EXTRA_ARGS EXCLUDE_FROM_ALL)

    # Yes, this has to replicate the complete signature of ExternalProject_Add.
    # Otherwise, we can't successfully parse out our own arguments amongst the noise.
    set(flags)
    set(oneValueArgs
        # Path options
        PREFIX
        TMP_DIR
        STAMP_DIR
        DOWNLOAD_DIR
        SOURCE_DIR
        BINARY_DIR
        INSTALL_DIR

        # Download step options
        URL_HASH
        URL_MD5
        DOWNLOAD_NAME
        DOWNLOAD_NO_EXTRACT
        DOWNLOAD_NO_PROGRESS
        TIMEOUT
        HTTP_USERNAME
        HTTP_PASSWORD
        TLS_VERIFY
        TLS_CAINFO

        # git
        GIT_REPOSITORY
        GIT_TAG
        GIT_REMOTE_NAME
        GIT_SUBMODULES
        GIT_SHALLOW
        GIT_PROGRESS

        # svn
        SVN_REPOSITORY
        SVN_REVISION
        SVN_USERNAME
        SVN_PASSWORD
        SVN_TRUST_CERT

        # hg
        HG_REPOSITORY
        HG_TAG

        # cvs
        CVS_REPOSITORY
        CVS_MODULE
        CVS_TAG

        # Update step..
        UPDATE_COMMAND
        UPDATE_DISCONNECTED
        PATCH_COMMAND

        # Configure step...
        CONFIGURE_COMMAND
        CMAKE_COMMAND
        CMAKE_GENERATOR
        CMAKE_GENERATOR_PLATFORM
        CMAKE_GENERATOR_TOOLSET
        SOURCE_SUBDIR

        # Build step
        BUILD_COMMAND
        BUILD_IN_SOURCE
        BUILD_ALWAYS

        # Install step
        INSTALL_COMMAND

        # Test step
        TEST_COMMAND
        TEST_BEFORE_INSTALL
        TEST_AFTER_INSTALL
        TEST_EXCLUDE_FROM_MAIN

        # Logging
        LOG_DOWNLOAD
        LOG_UPDATE
        LOG_CONFIGURE
        LOG_BUILD
        LOG_INSTALL
        LOG_TEST

        # Terminal access
        USES_TERMINAL_DOWNLOAD
        USES_TERMINAL_UPDATE
        USES_TERMINAL_CONFIGURE
        USES_TERMINAL_BUILD
        USES_TERMINAL_INSTALL
        USES_TERMINAL_TEST

        # Target options
        EXCLUDE_FROM_ALL

        # Misc
        LIST_SEPARATOR
    )
    set(multiValueArgs
        # Download step
        DOWNLOAD_COMMAND
        URL
        HTTP_HEADER

        # git
        GIT_CONFIG

        # Configure step...
        CMAKE_ARGS
        CMAKE_CACHE_ARGS
        CMAKE_CACHE_DEFAULT_ARGS

        # Build step...
        BUILD_BYPRODUCTS

        # Target options
        DEPENDS
        STEP_TARGETS
        INDEPENDENT_STEP_TARGETS

        # Misc
        COMMAND

        # Extra ones we added...
        STATIC_LIBRARIES
        DYNAMIC_LIBRARIES
        EXECUTABLES
    )

    cmake_parse_arguments("ep" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${EXTRA_ARGS})

    # A convenience: if it's a git-source, don't have an update command.
    if (ep_GIT_REPOSITORY)
        # Add `UPDATE_COMMAND ""`, the hard way
        set(EXTRA_ARGS "${EXTRA_ARGS};UPDATE_COMMAND;")
    endif ()

    # If it's a cmake buildsystem, sort out some of the cmake arguments ourselves.
    if (ep_CMAKE_ARGS)
        remove_argument(MULTI EXTRA_ARGS CMAKE_ARGS "${oneValueArgs};${multiValueArgs}")

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
        ${EXTRA_ARGS}
    )

    # Configure the exported targets...
    foreach (_LIB ${ep_STATIC_LIBRARIES})
        add_library(${_LIB} STATIC IMPORTED GLOBAL)

        # If the imported library is requested, actually build it.
        add_dependencies(${_LIB} ${TARGET})

        # Setup the imported target...
        set_target_properties(${_LIB} PROPERTIES
            IMPORTED_LOCATION ${EP_INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}${_LIB}${CMAKE_STATIC_LIBRARY_SUFFIX}
        )
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
