# Apply the default values (from the XCMAKE_* global variables) of all our custom target properties.
function(apply_default_properties TARGET)
    foreach (_I ${XCMAKE_TGT_PROPERTIES})
        set_target_properties(
            ${TARGET} PROPERTIES
            ${_I} "${XCMAKE_${_I}}"
        )
    endforeach()
endfunction()

# Each of the XCMAKE custom properties has a corresponding interface target describing its effect.
# If the property value is falsey, nothing happens.
# If the target <property_value>_<property_name>_EFFECTS exists, it is used.
# Otherwise, <property_name>_EFFECTS is used.
# (This makes it easy to have different effect groups for different values of a property - such as
# a sanitiser selector - and also to have simple on/off properties).
function(apply_effect_groups TARGET)
    foreach (_P ${XCMAKE_TGT_PROPERTIES})
        # Flag-style?
        if (TARGET ${_P}_EFFECTS)
            target_link_libraries(
                ${TARGET} PRIVATE
                $<IF:$<BOOL:$<TARGET_PROPERTY:${TARGET},${_P}>>,${_P}_EFFECTS,>
            )
        else()
            # Assume value-style and hope for the best...
            target_link_libraries(
                ${TARGET} PRIVATE
                $<IF:$<BOOL:$<TARGET_PROPERTY:${TARGET},${_P}>>,$<TARGET_PROPERTY:${TARGET},${_P}>_${_P}_EFFECTS,>
            )
        endif()
    endforeach()
endfunction()

macro(ensure_not_imported TARGET)
    # If it's an imported target, stop
    get_target_property(IS_IMPORTED ${TARGET} IMPORTED)
    if (IS_IMPORTED)
        return()
    endif ()
endmacro()

function(add_library TARGET)
    _add_library(${TARGET} ${ARGN})
    ensure_not_imported(${TARGET})

    # Apply our custom properties...
    apply_default_properties(${TARGET})
    apply_effect_groups(${TARGET})
endfunction()

function(add_executable TARGET)
    _add_library(${TARGET} ${ARGN})
    ensure_not_imported(${TARGET})
    apply_default_properties(${TARGET})
    apply_effect_groups(${TARGET})
endfunction()
