# Override option() so that if the value is already set in the cache we, instead of no-oping, add
# the documentation to it instead.
function (option VAR HELP)
    _option(${VAR} "${HELP}" "${ARGN}")

    set(DEFAULT "${ARGN}")
    if ("${DEFAULT}" STREQUAL "")
        set(DEFAULT OFF)
    endif()

    # Promote the variable to the cache if it isn't there already...
    # This is basically the non-stupid version of CMP0077.
    set(${VAR} ${DEFAULT} CACHE BOOL ${HELP})

    # So, if someone provided a value for the option before this call, CMP0077 makes _option() ignore it
    # but we promoted it to the cache (with helptext) above, so that works.
    # If the value wasn't defined at all prior to the call to option, then _option() will have made the
    # cache value with default value and the helptext.
    # The final case to handle is if a default value was already set in the cache (such as via the command
    # line or a different script). In which case, everything above will have been a no-op, and there will
    # be an existing cache value with the wrong helptext and advancedness properties. So let's fix those.
    ensure_documented(${VAR} "${HELP}" BOOL)
endfunction()

# Ensure that the cache variable VAR is visible, documented, and documented with the given help string.
function (ensure_documented VAR HELP TYPE)
    # We have to do it in this amusingly contrived way to avoid  writing to the cache unnecessarily
    # (and triggering a rebuild). This way, we'll only modify the cache if the cache has alreay
    # been modified earlier by whatever wrote the variable into the cache.
    get_property(HELPSTR CACHE ${VAR} PROPERTY HELPSTRING)
    if (NOT "${HELPSTR}" STREQUAL "${HELP}")
        set_property(CACHE ${VAR} PROPERTY HELPSTRING "${HELP}")
    endif ()

    get_property(OPTTYPE CACHE ${VAR} PROPERTY TYPE)
    if (NOT "${OPTTYPE}" STREQUAL "${TYPE}")
        set_property(CACHE ${VAR} PROPERTY TYPE "${TYPE}")
    endif ()
endfunction()
