# Wrap `install()` to allow installation of IMPORTED targets with `install(TARGETS...)`
function(install)
    # Now we need to do a more thorough job of parsing the arguments, alas.
    # install() actually has a bunch of argument groups, warranting the following rather elaborate two-level parsing:
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

    set(flags
        EXCLUDE_FROM_ALL
        OPTIONAL
    )
    set(oneValueArgs
        DESTINATION
        COMPONENT
    )
    set(multiValueArgs
        PERMISSIONS
        CONFIGURATIONS
    )
    set(PASSTHRU_FLAGS ${flags})
    set(PASSTHRU_ARGS ${oneValueArgs} ${multiValueArgs})

    # Parse each of the sub argment lists (to the extent that we care)
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
        foreach (SUBARG ${PASSTHRU_FLAGS})
            if (${${ITYPE}_${SUBARG}})
                list(APPEND ${ITYPE}_FORWARD ${SUBARG})
            endif()
        endforeach ()
    endforeach()

    # Set up default destinations to match cmake's normal semantics.
    default_value(RUNTIME_DESTINATION "${CMAKE_INSTALL_BINDIR}")
    default_value(LIBRARY_DESTINATION "${CMAKE_INSTALL_LIBDIR}")
    default_value(ARCHIVE_DESTINATION "${CMAKE_INSTALL_LIBDIR}")
    default_value(PUBLIC_HEADER_DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

    # Consider each target for special treatment, possibly delegating it to `install()`.
    foreach (TGT ${i_TARGETS})
        if (NOT TARGET ${TGT})
            message(FATAL_ERROR "Tried to install nonexistent target: ${TGT}")
        endif()

        # Delegate installation of non-IMPORTED targets
        get_target_property(IS_IMPORTED ${TGT} IMPORTED)
        if (NOT IS_IMPORTED)
            _install(TARGETS ${TGT} ${DELEGATE_ARGS})
            continue()
        endif()

        set(DEFAULT_PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ)

        # Install the imported target as a proper file.
        get_target_property(TGT_TYPE ${TGT} TYPE)

        get_target_property(FILE_PATH ${TGT} IMPORTED_LOCATION)
        get_target_property(IMPLIB_FILE_PATH ${TGT} IMPORTED_IMPLIB)

        # On DLL platforms, we need to set the key to RUNTIME for shared libraries
        if ("${TGT_TYPE}" STREQUAL SHARED_LIBRARY)
            if(IMPLIB_FILE_PATH)
                set(KEY RUNTIME)
            else()
                set(KEY LIBRARY)
            endif()
        elseif("${TGT_TYPE}" STREQUAL STATIC_LIBRARY)
            set(KEY ARCHIVE)
        elseif("${TGT_TYPE}" STREQUAL EXECUTABLE)
            set(KEY RUNTIME)
            list(APPEND DEFAULT_PERMISSIONS OWNER_EXECUTE GROUP_EXECUTE WORLD_EXECUTE)
        endif()

        set(PERMS "${${KEY}_PERMISSIONS}")
        default_value(PERMS "${DEFAULT_PERMISSIONS}")

        # If it's an EP target, set the OPTIONAL flag here and set up an existence assert if the stampfile exists
        # (meaning the installed file must exist if the EP target ran). If it isn't an EP target, the artefact is
        # expected to exist unconditionally.
        handleEP(${FILE_PATH})

        install(FILES "${FILE_PATH}" ${OPT_FLAG}
            PERMISSIONS "${PERMS}"
            DESTINATION "${${KEY}_DESTINATION}"
            ${${KEY}_FORWARD}
        )

        # Handle implib installation if present
        if(IMPLIB_FILE_PATH)
            handleEP(${IMPLIB_FILE_PATH})

            install(FILES "${IMPLIB_FILE_PATH}" ${OPT_FLAG}
                PERMISSIONS "${PERMS}"
                DESTINATION "${ARCHIVE_DESTINATION}"
                ${ARCHIVE_FORWARD}
            )
        endif()

    endforeach()
endfunction()

macro(handleEP CHECKPATH)
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
