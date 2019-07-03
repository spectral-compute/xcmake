# Override option() so that if the value is already set in the cache we, instead of no-oping, add
# the documentation to it instead.
# Arguments are optionName, helpString, DefaultValue, optionType, ListOfValidStrings
# The list of valid strings specifies the list of acceptable values for the option if it is of STRING type.
# All options beyong "helpString" are optional.
function (option VAR HELP)
    default_value(ARGV2 "OFF")
    default_value(ARGV3 "BOOL")
    default_value(ARGV4 "")

    set(DEFAULT "${ARGV2}")
    set(TYPE "${ARGV3}")
    set(VALID_VALUES "${ARGV4}")

    if (TYPE STREQUAL BOOL)
        _option(${VAR} "${HELP}" "${DEFAULT}")
    endif()

    # Promote the variable to the cache if it isn't there already...
    # This is basically the non-stupid version of CMP0077.
    unset(${VAR}) # Clear the variable from the function scope, so we can see a cached version
    if (NOT DEFINED ${VAR})
        # Set the default, promoting the value to the cache.
        set(${VAR} "${DEFAULT}" CACHE "${TYPE}" "${HELP}")
    endif()

    # So, if someone provided a value for the option before this call, CMP0077 makes _option() ignore it
    # but we promoted it to the cache (with helptext) above, so that works.
    # If the value wasn't defined at all prior to the call to option, then _option() will have made the
    # cache value with default value and the helptext.
    # The final case to handle is if a default value was already set in the cache (such as via the command
    # line or a different script). In which case, everything above will have been a no-op, and there will
    # be an existing cache value with the wrong helptext and advancedness properties. So let's fix those.

    ensure_documented(${VAR} "${HELP}" ${TYPE} "${VALID_VALUES}")

    validateOption(${VAR})
endfunction()

# Explode if an option has a value excluded by its list of allowed values.
function(validateOption VAR)
    get_property(CVAL CACHE ${VAR} PROPERTY VALUE)
    get_property(OPTTYPE CACHE ${VAR} PROPERTY TYPE)
    get_property(VALID_STRINGS CACHE ${VAR} PROPERTY STRINGS)

    if (${OPTTYPE} STREQUAL "STRING" AND NOT "${VALID_STRINGS}" STREQUAL "")
        foreach (_S IN LISTS VALID_STRINGS)
            if ("${_S}" STREQUAL "${CVAL}")
                return()
            endif()
        endforeach()

        string(REPLACE ";" ", " PRETTY_OPTS "${VALID_STRINGS}")
        message(FATAL_ERROR "Invalid value \"${CVAL}\" specified for ${VAR}.\nValid values are: ${PRETTY_OPTS}")
    endif()
endfunction()

# Ensure that the cache variable VAR is visible, documented, and documented with the given help string.
function (ensure_documented VAR HELP TYPE VALID_VALUES)
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

    if ("${TYPE}" STREQUAL "STRING")
        get_property(VALID_STRINGS CACHE ${VAR} PROPERTY STRINGS)
        if (NOT "${VALID_VALUES}" STREQUAL "${VALID_STRINGS}")
            set_property(CACHE ${VAR} PROPERTY STRINGS "${VALID_VALUES}")
        endif()
    endif()
endfunction()
