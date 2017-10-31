include(GenerateExportHeader)

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

# Global effects are basically global flags that define a function to run on targets.
function(apply_global_effects TARGET)
    foreach (_P ${XCMAKE_GLOBAL_PROPERTIES})
        if (XCMAKE_${_P})
            dynamic_call(${_P}_EFFECTS ${TARGET})
        endif()
    endforeach()
endfunction()

# Apply standard CMake properties that we set to specific values.
function(apply_default_standard_properties TARGET)
    # C++17, always.
    set_target_properties(${TARGET} PROPERTIES
        CXX_EXTENSIONS OFF
        CXX_STANDARD 17
        CXX_STANDARD_REQUIRED ON
    )

    target_compile_options(${TARGET} PRIVATE
        -Wall -Wextra -Wpedantic -Wdocumentation
    )
endfunction()

macro(ensure_not_imported TARGET)
    # If it's an imported target, stop
    get_target_property(IS_IMPORTED ${TARGET} IMPORTED)
    if (IS_IMPORTED)
        return()
    endif ()
endmacro()

macro(ensure_not_object TARGET)
    # If it's an object library target, stop
    get_target_property(T_TYPE ${TARGET} TYPE)
    if ("${T_TYPE}" STREQUAL "OBJECT_LIBRARY")
        return()
    endif ()
endmacro()

function(add_library TARGET)
    _add_library(${TARGET} ${ARGN})

    # Imported targets definitely do not need to have their properties futzed with.
    ensure_not_imported(${TARGET})

    apply_global_effects(${TARGET})

    # Object libraries inherit their target properties from what they get assimilated by,
    # so they stop here.
    ensure_not_object(${TARGET})

    # Apply our custom properties...
    apply_default_standard_properties(${TARGET})
    apply_default_properties(${TARGET})
    apply_effect_groups(${TARGET})

    install(
        TARGETS ${TARGET}
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
    )

    # Libraries need export headers!
    set_target_properties(${TARGET} PROPERTIES
        CXX_VISIBILITY_PRESET "hidden"
        VISIBILITY_INLINES_HIDDEN ON
    )
    set(EXPORT_HEADER_DIR ${CMAKE_BINARY_DIR}/generated/exportheaders)
    file(MAKE_DIRECTORY ${EXPORT_HEADER_DIR})
    target_include_directories(${TARGET} PRIVATE ${EXPORT_HEADER_DIR})
    set(EXPORT_HDR_PATH ${EXPORT_HEADER_DIR}/${TARGET}/export.h)
    generate_export_header(${TARGET} EXPORT_FILE_NAME ${EXPORT_HDR_PATH})
    install(FILES ${EXPORT_HDR_PATH} DESTINATION ./include/${TARGET} RENAME export.h)
endfunction()

function(add_executable TARGET)
    _add_executable(${TARGET} ${ARGN})
    ensure_not_imported(${TARGET})
    apply_default_standard_properties(${TARGET})
    apply_default_properties(${TARGET})
    apply_effect_groups(${TARGET})
    apply_global_effects(${TARGET})

    install(
        TARGETS ${TARGET}
        RUNTIME DESTINATION bin
    )
endfunction()
