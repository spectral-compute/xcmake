include(GenerateExportHeader)

# Find all the source files for enabled languages according to the given pattern.
function(find_sources OUT)
    # Build the glob pattern using the list of enabled languages.
    set(GLOB_PATTERN "")
    get_property(LANGS_ENABLED GLOBAL PROPERTY ENABLED_LANGUAGES)
    foreach (_L ${LANGS_ENABLED})
        # A most useful global variable
        set(SOURCE_EXTENSIONS ${CMAKE_${_L}_SOURCE_FILE_EXTENSIONS})

        if (${_L} STREQUAL "CXX")
            # cmake's CUDA support conflicts with our own, so we have to carefully work around it.
            # We teach cmake that *.cu is C++, not CUDA.
            list(APPEND SOURCE_EXTENSIONS "cu")

            # For improved IDE support, include header files as source in IDEs, causing complete
            # indexing :D
            if ($ENV{CLION_IDE})
                list(APPEND SOURCE_EXTENSIONS "h" "hpp" "cuh")
            endif ()
        endif()

        # Construct the glob expression from the source extensions.
        foreach (_SRCARG ${ARGN})
            # If the input was a single file, just add it (instead of gluing extensions on).
            if (EXISTS "${_SRCARG}" AND NOT IS_DIRECTORY "${_SRCARG}")
                list(APPEND GLOB_PATTERN "${_SRCARG}")
            else()
                foreach (_E ${SOURCE_EXTENSIONS})
                    list(APPEND GLOB_PATTERN "${_SRCARG}/*.${_E}")
                endforeach()
            endif()
        endforeach()
    endforeach()

    file(GLOB_RECURSE FOUND_SOURCES
        LIST_DIRECTORIES OFF
        ${GLOB_PATTERN}
    )

    set(${OUT} ${FOUND_SOURCES} PARENT_SCOPE)
endfunction()

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

    target_compile_options(${TARGET} BEFORE PRIVATE
        -Weverything # We like warnings.

        # Obviously none of these make sense.
        -Wno-c++98-c++11-c++14-c++17-compat-pedantic
        -Wno-c++98-compat-pedantic
        -Wno-c++11-compat-pedantic
        -Wno-c++14-compat-pedantic

        -Wno-old-style-cast
        -Wno-undef
        -Wno-reserved-id-macro               # This isn't really relevant any more.
        -Wno-exit-time-destructors           # We *use* these!
        -Wno-padded
        -Wno-shadow-field-in-constructor     # Sorry Nick, I like doing this. :D
        -Wno-global-constructors             # We also use these
        -Wno-missing-prototypes
        -Wno-switch-enum                     # This is stupid.
        -Wno-unused-template                 # ... We're writing a template library...
        -Wno-float-equal                     # This isn't always wrong...
        -Wno-undefined-func-template         # Sometimes we like to link templates together, because we're mad.
        -Wno-cast-align                      # TODO: Enable this one.
        -Wno-sign-conversion                 # Just too irritating. Can't use int to access std::vectors...
        -Wno-conversion                      # Can't do literal arrays of templated type due to implicit conversions.

        # Re-enable parts of `-Wconversion` that we can cope with.
        -Wdouble-promotion                   # Warn about implicit double promotion: a common performance problem.
        -Wbitfield-enum-conversion           # Conversion from enum to a too-short bitfield.
        -Wbool-conversion                    # Initialising a pointer from a bool. Wat.
        -Wconstant-conversion
        -Wenum-conversion                    # No implicit conversion between enums.
        -Wfloat-conversion                   # No implicit float->int conversions.
        -Wint-conversion                     # No implicit integer<->pointer conversions.
        -Wliteral-conversion                 # No implicit value-changing literal conversions.
        -Wnon-literal-null-conversion        # No implicit zero-literal-to-nullptr conversions.
        -Wnull-conversion                    # No implicit nullptr-to-zero-literal conversions.
        -Wshorten-64-to-32                   # No implicit conversion from longer ints to shorter ones.
        -Wstring-conversion                  # No implicit string literal to bool conversion.

        -Werror # We *really* like warnings.

        -ftemplate-backtrace-limit=256       # We have some insane templates.
        -fstrict-vtable-pointers             # An experimental but year-old and safe optimisation that helps BLASBAT :D

        # Prevent false positives from -Wdocumentation-unknown-command
        -fcomment-block-commands=file
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

# Sets the library's default symbol visivility to hidden, and generate an export header.
#
# Mandatory single variable arguments:
#    TARGET The target to apply the symbol hiding to.
#
# Flags:
#    NOINSTALL Don't install the header. This is useful for internal libraries that are only used by other targets in
#              the same cmake project.
#
# Optional single variable arguments:
#    BASE_NAME The base name to give to generate_export_header(). By default, ${TARGET} is used.
#    EXPORT_FILE_NAME The file path to for the generated header to give to generate_export_header(). Note: this is
#                     always prefixed by a directory into which xcmake puts generated files. The installation location
#                     is prefixed by "include".
#    INCLUDE_PATH_SUFFIX Append this suffix to the include directory added to the target. This is useful if, for
#                        example, the header would normally be included relative to other installed headers which would
#                        be placed on the include path with the given suffix.
function(add_export_header TARGET)
    # Parse arguments.
    cmake_parse_arguments(args "NOINSTALL" "BASE_NAME;EXPORT_FILE_NAME;INCLUDE_PATH_SUFFIX" "" ${ARGN})

    set(BASE_NAME ${TARGET})
    if (args_BASE_NAME)
        set(BASE_NAME ${args_BASE_NAME})
    endif()

    set(EXPORT_FILE_NAME ${TARGET}/export.h)
    if (args_EXPORT_FILE_NAME)
        set(EXPORT_FILE_NAME ${args_EXPORT_FILE_NAME})
    endif()

    # Make somewhere to put the header.
    set(EXPORT_HEADER_DIR ${CMAKE_BINARY_DIR}/generated/exportheaders)
    file(MAKE_DIRECTORY ${EXPORT_HEADER_DIR})
    target_include_directories(${TARGET} PUBLIC $<BUILD_INTERFACE:${EXPORT_HEADER_DIR}/${args_INCLUDE_PATH_SUFFIX}>)

    # Calculate the absolute header path, and the relative directory for the header.
    set(EXPORT_HDR_PATH ${EXPORT_HEADER_DIR}/${EXPORT_FILE_NAME})
    get_filename_component(EXPORT_DIRECTORY_NAME "${EXPORT_FILE_NAME}" DIRECTORY)

    # Generate the header.
    generate_export_header(${TARGET} BASE_NAME "${BASE_NAME}" EXPORT_FILE_NAME "${EXPORT_HDR_PATH}")

    # Install the header.
    if (NOT args_NOINSTALL)
        install(FILES "${EXPORT_HDR_PATH}" DESTINATION "./include/${EXPORT_DIRECTORY_NAME}")
    endif()

    # Fix IDE indexing of the header.
    target_include_directories(${TARGET} PRIVATE ${EXPORT_HEADER_DIR})
endfunction()

function(add_library TARGET)
    cmake_parse_arguments(args "NOINSTALL;NOEXPORT" "" "" ${ARGN})

    _add_library(${TARGET} ${args_UNPARSED_ARGUMENTS})

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

    if (NOT args_NOINSTALL)
        if (NOT args_NOEXPORT)
            set(EXPORT_FLAGS EXPORT ${PROJECT_NAME})
            message_colour(STATUS Red "Adding ${TARGET} to export set ${PROJECT_NAME}")
        endif()
        install(TARGETS ${TARGET} ${EXPORT_FLAGS} ARCHIVE DESTINATION lib LIBRARY DESTINATION lib)

        # TODO: Could be an overridden install(), but holy crap that's complicated.
        set_target_properties(${TARGET} PROPERTIES INSTALL_RPATH "$ORIGIN/../lib")
    endif()
endfunction()

function(add_executable TARGET)
    cmake_parse_arguments(args "NOINSTALL" "" "" ${ARGN})

    _add_executable(${TARGET} ${args_UNPARSED_ARGUMENTS})
    ensure_not_imported(${TARGET})
    apply_default_standard_properties(${TARGET})
    apply_default_properties(${TARGET})
    apply_effect_groups(${TARGET})
    apply_global_effects(${TARGET})

    if (NOT args_NOINSTALL)
        install(TARGETS ${TARGET} RUNTIME DESTINATION bin)

        # TODO: Could be an overridden install(), but holy crap that's complicated.
        set_target_properties(${TARGET} PROPERTIES INSTALL_RPATH "$ORIGIN/../lib")
    endif()
endfunction()

# All targets should, by default, have hidden visibility. This isn't in the toolchain because it's useful to be able to
# build others' libraries with that toolchain.
default_value(CMAKE_CXX_VISIBILITY_PRESET "hidden")
default_value(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

# A "make all the documentation" target. The scripts that make documentation targets attach their targets to this.
add_custom_target(docs ALL)
