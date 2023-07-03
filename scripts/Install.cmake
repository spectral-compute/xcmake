# Wrap `install()` to allow installation of IMPORTED targets with `install(TARGETS...)`
function(install)
    if (XCMAKE_PROJECTS_ARE_COMPONENTS AND ((NOT CMAKE_INSTALL_DEFAULT_COMPONENT_NAME) OR
                                            (CMAKE_INSTALL_DEFAULT_COMPONENT_NAME STREQUAL "Unspecified")))
        set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME "${PROJECT_NAME}")
    endif()

    set(COMPONENT_INSTALL_ROOT)
    if (XCMAKE_PROJECT_INSTALL_PREFIX)
        set(COMPONENT_INSTALL_ROOT ${PROJECT_NAME}/)
    endif()

    # Find every "DESTINATION" keyword, and prepend the extra prefix to the argument following it.
    list(LENGTH ARGN ITERATION_LIMIT)
    math(EXPR ITERATION_LIMIT "${ITERATION_LIMIT} - 1") # Because the range iteration goes one step further than it should do...

    foreach(I RANGE 0 ${ITERATION_LIMIT})
        list(GET ARGN ${I} ARG)

        if ("${ARG}" STREQUAL "DESTINATION")
            # Fix the subsequent argument...
            math(EXPR PATH_IDX "${I} + 1")

            # Replace the destination path with a version that has the prefix prepended on.
            list(GET ARGN ${PATH_IDX} THE_PATH)
            set(THE_PATH "${COMPONENT_INSTALL_ROOT}${THE_PATH}")
            list(REMOVE_AT ARGN ${PATH_IDX})
            list(INSERT ARGN ${PATH_IDX} "${THE_PATH}")
        endif()
    endforeach()

    set(installTypes
        ARCHIVE
        LIBRARY
        RUNTIME
        OBJECTS
        FRAMEWORK
        BUNDLE
        PRIVATE_HEADER
        PUBLIC_HEADER
        RESOURCE
    )

    set(multiValueArgs
        TARGETS
        EXPORT
        INCLUDES
    )
    cmake_parse_arguments("i" "EP_TARGET" "" "${multiValueArgs};${installTypes}" "${ARGN}")

    # CODE and SCRIPT mode we must flee screaming from, since they lack a DESTINATION argument to fix.
    list(GET ARGN 0 FIRST_MODE)
    if ("${FIRST_MODE}" STREQUAL CODE OR "${FIRST_MODE}" STREQUAL SCRIPT)
        _install(${ARGN}) # Leave me alone!
    endif()

    # If it isn't a TARGETS-mode install, delegate entirely.
    if ("${i_TARGETS}" STREQUAL "")
        _install(${ARGN})
        return()
    endif ()

    # Form the list of top-level arguments excluding TARGETS.
    set(ARGS_SANS_TARGETS ${multiValueArgs} ${installTypes})
    list(REMOVE_ITEM ARGS_SANS_TARGETS TARGETS)

    # Reassemble the entire argument list, minus the TARGETS.
    set(DELEGATE_ARGS "")
    foreach (ARG ${ARGS_SANS_TARGETS})
        if (NOT "${i_${ARG}}" STREQUAL "")
            list(APPEND DELEGATE_ARGS ${ARG} "${i_${ARG}}")
        endif()
    endforeach()

    # These define the options to `install(TARGETS)` that are also accepted by `install(FILES)`. We preseve them when
    # installing imported projects using `install(FILES)`.
    set(flags EXCLUDE_FROM_ALL OPTIONAL)
    set(oneValueArgs DESTINATION COMPONENT)
    set(multiValueArgs PERMISSIONS CONFIGURATIONS)
    set(PASSTHRU_FLAGS ${flags})
    set(PASSTHRU_ARGS ${oneValueArgs} ${multiValueArgs})

    # Parse each of the sub argment lists and construct a list of arguments from each that are compatible with FILES
    # mode. These will be passed along for each IMPORTED target being installed.
    # This also parses out arguments like `PERMISSIONS` that we need to provide default values for when using FILES mode
    # but which we want to pass along if the user specified them explicitly.
    foreach (ITYPE ${installTypes})
        default_value(I_${ITYPE} "")
        cmake_parse_arguments("${ITYPE}" "${flags}" "${oneValueArgs}" "${multiValueArgs}" "${I_${ITYPE}}")

        # Assemble a new argument list for each group with the arguments that can be directly passed through to
        # `install(FILES...)`
        set(${ITYPE}_FORWARD "")
        foreach (SUBARG ${PASSTHRU_ARGS})
            if (NOT "${${ITYPE}_${SUBARG}}" STREQUAL "")
                list(APPEND ${ITYPE}_FORWARD ${SUBARG} ${${ITYPE}_${SUBARG}})
            endif()
        endforeach()

        # Flags need handling specially, since their value is just the identifier.
        foreach (SUBARG ${PASSTHRU_FLAGS})
            if (${${ITYPE}_${SUBARG}})
                list(APPEND ${ITYPE}_FORWARD ${SUBARG})
            endif()
        endforeach ()
    endforeach()

    # Set up default destinations to match cmake's normal semantics for `install(TARGETS)`. A TARGETS install with no
    # destination uses these by default. FILES-mode has no default, so if we're doing an IMPORTED target install we need
    # to manually replicate that behaviour here.
    default_value(RUNTIME_DESTINATION "${CMAKE_INSTALL_BINDIR}")
    default_value(LIBRARY_DESTINATION "${CMAKE_INSTALL_LIBDIR}")
    default_value(ARCHIVE_DESTINATION "${CMAKE_INSTALL_LIBDIR}")
    default_value(PUBLIC_HEADER_DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

    # We also need to synthesise a `PERMISSIONS` argument for `FILES`-mode to replicate the default behaviour of TARGETS
    # mode, which sets the execute bit on executables. However, TARGETS-mode also does tak a PERMISSIONS argument, so
    # this is only a _default_ value (since the above argument parsing will have already set a concrete value if one
    # was specified by the caller).
    default_value(RUNTIME_PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ OWNER_EXECUTE GROUP_EXECUTE WORLD_EXECUTE)
    default_value(LIBRARY_PERMISSIONS ${RUNTIME_PERMISSIONS})
    set(DEFAULT_PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ)

    # Handle each target with a separate call to install. This lets us filter out the IMPORTED ones. The non-imported
    # ones just get passed to `_install()` with the rest of the argument list.
    foreach (TGT ${i_TARGETS})
        if (NOT TARGET ${TGT})
            # `_install(TARGETS)` has a nice error for this, but our proxying means we need to reimplement it otherwise
            # you instead get a crazy confusing error from the logic below.
            message(FATAL_ERROR "Tried to install nonexistent target: ${TGT}")
        endif()

        # Add the `COMPONENT_INSTALL_ROOT` to the `INTERFACE_INCLUDE_DIRECTORIES` property of targets so that anything which links to them
        # is able to find things once installed
        get_target_property(TGT_INTERFACE_INCLUDES ${TGT} INTERFACE_INCLUDE_DIRECTORIES)
        if (TGT_INTERFACE_INCLUDES)
            string(REGEX REPLACE "\\\$<INSTALL_INTERFACE:(.*)>" "$<INSTALL_INTERFACE:${COMPONENT_INSTALL_ROOT}\\1>" TGT_INST_INT ${TGT_INTERFACE_INCLUDES})
            set_target_properties(${TGT} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${TGT_INST_INT})
        endif ()

        get_target_property(TGT_TYPE ${TGT} TYPE)

        # Determine the "key" used for this target. This will be one of the keywords from target-mode install, listed
        # above in `installTypes`.
        if ("${TGT_TYPE}" STREQUAL SHARED_LIBRARY)
            if(XCMAKE_IMPLIB_PLATFORM) # On DLL platforms, we need to set the key to RUNTIME for shared libraries
                set(KEY RUNTIME)
            else()
                set(KEY LIBRARY)
            endif()
        elseif("${TGT_TYPE}" STREQUAL STATIC_LIBRARY)
            set(KEY ARCHIVE)
        elseif("${TGT_TYPE}" STREQUAL EXECUTABLE)
            set(KEY RUNTIME)

            # Install any symlink folders
            if(XCMAKE_IMPLIB_PLATFORM AND XCMAKE_INSTALL_DEPENDENT_DLLS)
                get_target_property(EXE_DIR ${TGT} RUNTIME_OUTPUT_DIRECTORY)
                install(DIRECTORY "${EXE_DIR}/${TGT}_SYMLINKS/"
                    DESTINATION "${${KEY}_DESTINATION}"
                )
            endif()
        endif()

        # Delegate installation of non-IMPORTED targets
        get_target_property(IS_IMPORTED ${TGT} IMPORTED)
        if (NOT IS_IMPORTED)
            _install(TARGETS ${TGT} ${DELEGATE_ARGS})
            continue()
        endif()

        # If it's an EP target, set the OPTIONAL flag here and set up an existence assert if the stampfile exists
        # (meaning the installed file must exist if the EP target ran). If it isn't an EP target, the artefact is
        # expected to exist unconditionally.
        get_target_property(FILE_PATH ${TGT} IMPORTED_LOCATION)
        handle_ep(${FILE_PATH})

        default_value(${KEY}_PERMISSIONS "${DEFAULT_PERMISSIONS}")

        # Install the imported target's main file.
        install_following_symlinks("${FILE_PATH}"
            "${${KEY}_DESTINATION}"
            "${${KEY}_PERMISSIONS}"
#            ${${KEY}_FORWARD}
        )

        # Install the imported target's IMPLIB, if it has one.
        if (XCMAKE_IMPLIB_PLATFORM AND "${TGT_TYPE}" STREQUAL "SHARED_LIBRARY")
            get_target_property(IMPLIB_FILE_PATH ${TGT} IMPORTED_IMPLIB)
            if(NOT IMPLIB_FILE_PATH)
                message(FATAL_ERROR "IMPORTED_IMPLIB not populated for shared library ${TGT}.")
            endif()

            handle_ep(${IMPLIB_FILE_PATH})

            install_following_symlinks(FILES "${IMPLIB_FILE_PATH}"
                "${ARCHIVE_DESTINATION}"
                "${${KEY}_PERMISSIONS}"
#                ${ARCHIVE_FORWARD}
            )
        endif()
    endforeach()
endfunction()

function(install_following_symlinks FILE DESTINATION PERMISSIONS)
    while (IS_SYMLINK ${FILE})
        install(FILES "${FILE}" ${OPT_FLAG}
            PERMISSIONS ${PERMISSIONS}
            DESTINATION "${DESTINATION}"
        )

        # Look through this symlink and update "FILE"
        file(READ_SYMLINK "${FILE}" RES)
        if (NOT IS_ABSOLUTE "${RES}")
            get_filename_component(DIR "${FILE}" DIRECTORY)
            set(RES "${DIR}/${RES}")
        endif()
        set(FILE "${RES}")
    endwhile ()

    install(FILES "${FILE}" ${OPT_FLAG}
        PERMISSIONS ${PERMISSIONS}
        DESTINATION "${DESTINATION}"
    )
endfunction()

macro(handle_ep CHECKPATH)
    set(OPT_FLAG "")
    if(i_EP_TARGET)
        set(OPT_FLAG "OPTIONAL")
        get_final_stamp_path(STAMPFILE ${TGT})

        # Crash if, at install time, the artefact does not exist but the stamp file does.
        # This can be conditionally disabled for generators that don't like `install(CODE...)`. It's only here to
        # avoid the nasty situation where EP builds would silently fail if they were misconfigured and the
        # `install(FILES...)` call was merely made `OPTIONAL`.
        install(CODE
            "if (NOT EXISTS \"${CHECKPATH}\" AND EXISTS \"${STAMPFILE}\") \n\
                message(FATAL_ERROR \"No such file or directory:\\n   ${CHECKPATH}\\nDid you misconfigure your external project?\") \n\
            endif()"
        )
    endif()
endmacro()

function (install_imported_headers TGT DEST)
    get_target_property(TGT_INTERFACE_INCLUDES ${TGT} INTERFACE_INCLUDE_DIRECTORIES)
    message("${TGT}")
    message("${TGT_INTERFACE_INCLUDES}")
    foreach (H IN LISTS TGT_INTERFACE_INCLUDES)
        message("${H}")
        install(DIRECTORY ${H}/ DESTINATION ./include/${DEST})
    endforeach ()
endfunction()
