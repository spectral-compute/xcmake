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
    cmake_parse_arguments("i" "" "" "${multiValueArgs};${installTypes}" "${ARGN}")

    # If it isn't a TARGETS-mode install, delegate entirely.
    if ("${i_TARGETS}" STREQUAL "")
        message_colour(STATUS Green "Full Delegate!")
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

    # Consider each target for special treatment, possibly delegating it to `install()`.
    foreach (TGT ${i_TARGETS})
        if (NOT TARGET ${TGT})
            message_colour(FATAL_ERROR BoldRed "Tried to install nonexistent target: ${TGT}")
        endif()

        get_target_property(IS_IMPORTED ${TGT} IMPORTED)
        get_target_property(TGT_TYPE ${TGT} TYPE)
        if (NOT IS_IMPORTED)
            # Delegate!
            _install(TARGETS ${TGT} ${DELEGATE_ARGS})
            continue()
        endif()
    endforeach()
endfunction()
