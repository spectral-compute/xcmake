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
        foreach (_E ${SOURCE_EXTENSIONS})
            foreach (_SRCDIR ${ARGN})
                list(APPEND GLOB_PATTERN ${_SRCDIR}/*.${_E})
            endforeach()
        endforeach()
    endforeach()

    file(GLOB_RECURSE FOUND_SOURCES ${GLOB_PATTERN})
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

    target_compile_options(${TARGET} PRIVATE
        -Wall
        -Wextra
        -Wpedantic
        -Wdocumentation
        -Werror
        -Wnewline-eof
        -ftemplate-backtrace-limit=0
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
    cmake_parse_arguments(args "" "BASE_NAME;EXPORT_FILE_NAME;INCLUDE_PATH_SUFFIX" "" ${ARGN})

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
    install(FILES "${EXPORT_HDR_PATH}" DESTINATION "./include/${EXPORT_DIRECTORY_NAME}")

    # Fix IDE indexing of the header.
    target_include_directories(${TARGET} PRIVATE ${EXPORT_HEADER_DIR})
endfunction()

function(add_library TARGET)
    cmake_parse_arguments(args "NOINSTALL" "" "" ${ARGN})

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
        install(TARGETS ${TARGET} EXPORT ${PROJECT_NAME} ARCHIVE DESTINATION lib LIBRARY DESTINATION lib)
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
    endif()
endfunction()

# All targets should, by default, have hidden visibility. This isn't in the toolchain because it's useful to be able to
# build others' libraries with that toolchain.
default_value(CMAKE_CXX_VISIBILITY_PRESET "hidden")
default_value(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
