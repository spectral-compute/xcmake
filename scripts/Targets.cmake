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
            if (DEFINED ENV{CLION_IDE})
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

# Link LIBRARY into TARGET at level LEVEL if the final value of PROPERTY is truthy.
function(link_if_property_set TARGET PROPERTY LEVEL LIBRARY)
    target_link_libraries(
        ${TARGET} ${LEVEL}
        $<IF:$<BOOL:$<TARGET_PROPERTY:${TARGET},${PROPERTY}>>,${LIBRARY},>
    )
endfunction()

# Each of the XCMAKE custom properties is defined either by interface targets or a function.
#
# For property "FOO":
# - If target FOO_EFFECTS exists, and target property value FOO is truthy, FOO_EFFECTS is linked to ${TARGET}.
# - If function FOO_EFFECTS() exists, it is called with ${TARGET}
# - Otherwise, ${TARGET} is linked to interface target ${FOO}_FOO_EFFECTS. That is, the value of the target property
#   identifies the interface target to link.
function(apply_effect_groups TARGET)
    foreach (_P ${XCMAKE_TGT_PROPERTIES})
        if (TARGET ${_P}_EFFECTS)
            # Flag-style: link to FOO_EFFECTS if the property is truthy.
            link_if_property_set(${TARGET} ${_P} PRIVATE ${_P}_EFFECTS)
        elseif(COMMAND ${_P}_EFFECTS)
            # Function-style: call function FOO_EFFECTS(${TARGET})
            # Note: the value of the property shouldn't be passed here. If desired, the implementation can access it
            #       using generator expressions. Accessing it here would mean later changes are ignored...
            dynamic_call(${_P}_EFFECTS ${TARGET})
        else()
            # Value-style: link to ${FOO}_FOO_EFFECTS, where ${FOO} is the value of the target property FOO.
            link_if_property_set(${TARGET} ${_P} PRIVATE $<TARGET_PROPERTY:${TARGET},${_P}>_${_P}_EFFECTS)
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

    set_target_properties(${TARGET} PROPERTIES INSTALL_RPATH "$ORIGIN/../lib")

    # Compiler flags that should be unconditionally applied to *everything*.
    # Since these flags go ahead of any others, individual targets can add their own flags to override things (such as
    # disabling warnings). In general though, we aim to avoid doing that, and if we are disabling a warning, it's
    # preferable to do so with an inline pragma around the silly bit of code.
    #
    # Optimisation flags don't belong here. Those probably want to go in either CUDA.cmake or OPT_LEVEL.cmake.
    target_compile_options(${TARGET} BEFORE PRIVATE
        -Weverything # We like warnings.

        # Don't warn for using cool things.
        -Wno-c++98-c++11-c++14-c++17-compat-pedantic
        -Wno-c++98-compat-pedantic
        -Wno-c++11-compat-pedantic
        -Wno-c++14-compat-pedantic
        -Wno-spectral-extensions

        -Wno-error-pass-failed
        -Wno-unknown-warning-option          # Don't crash old compilers. Unless they're so old they don't have this.

        -Wno-old-style-cast                  # It's sometimes nice to do C-style casts...
        -Wno-reserved-id-macro               # This isn't really relevant any more.
        -Wno-exit-time-destructors           # We *use* these!
        -Wno-padded
        -Wno-shadow-field
        -Wno-shadow-field-in-constructor     # Sorry Nick, I like doing this. :D
        -Wshadow-field-in-constructor-modified # The above turns this off, but we want it back on.
        -Wno-global-constructors             # We also use these
        -Wno-missing-prototypes
        -Wno-switch-enum                     # This is stupid.
        -Wno-unused-template                 # ... We're writing a template library...
        -Wno-float-equal                     # This isn't always wrong...
        -Wno-undefined-func-template         # Sometimes we like to link templates together, because we're mad.
        -Wno-sign-conversion                 # Just too irritating. Can't use int to access std::vectors...
        -Wno-comma                           # Half of our code is "misuse of the comma operator"
        -Wno-conversion                      # Can't do literal arrays of templated type due to implicit conversions.
        -Wno-trigraphs                       # Regexes often contain trigraphs, and we do indeed want to ignore them :D
        -Wno-format-nonliteral               # Being warned that a format parmaeter is nonliteral isn't helpful.
        -Wno-ctad-maybe-unsupported          # Don't forbid implicit class template argument deduction guides...

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

        # Warnings that appear to be broken.
        -Wno-weak-template-vtables           # Incorrectly warns about explicit instantiations in .cpp.
        -Wno-weak-vtables

        # We *really* like warnings.
        -Werror

        -ftemplate-backtrace-limit=256       # We have some insane templates.
        -fconstexpr-backtrace-limit=256      # We have some insane constexpr functions, too.
        -fconstexpr-depth=65535              # Maximum constexpr call depth. We have a regex compiler, soo...
        -fconstexpr-steps=33554432           # Lots, but infinite loops still get diagnosed within a few seconds.

        # Prevent false positives from -Wdocumentation-unknown-command
        -fcomment-block-commands=file,copydoc,concepts,satisfy,copydetails

        # Make errors more readable in the presence of insane templates
        -fdiagnostics-show-template-tree
        -fdiagnostics-show-option
        -fdiagnostics-show-category=name

        # Emit an error if we accidentally code-gen jumbo-sized objects (even if these would be removed by optimization,
        # it's better not to generate them in the first place).
        -fmax-data-global-size=67108864 -fmax-data-local-size=1048576
    )
endfunction()

macro(ensure_not_imported TARGET)
    # If it's an imported target, stop
    get_target_property(IS_IMPORTED ${TARGET} IMPORTED)
    if (IS_IMPORTED)
        return()
    endif ()
endmacro()

macro(ensure_not_interface TARGET)
    # If it's an interface library target, stop
    get_target_property(T_TYPE ${TARGET} TYPE)
    if ("${T_TYPE}" STREQUAL "INTERFACE_LIBRARY")
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

# Sets the library's default symbol visibility to hidden, and generate an export header.
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

function(fix_source_file_properties TARGET)
    # Never, ever tell cmake that anything is CUDA. We do it our own way.
    get_target_property(SOURCE_FILES ${TARGET} SOURCES)

    # This probably isn't fast.
    foreach(_F in ${SOURCE_FILES})
        get_source_file_property(CUR_LANG "${_F}" LANGUAGE)
        get_filename_component(FILE_EXT "${_F}" EXT)

        if ((${CUR_LANG} STREQUAL "CUDA") OR ("${FILE_EXT}" STREQUAL ".cu") OR ("${FILE_EXT}" STREQUAL ".cuh"))
            # This disables cmake's built-in CUDA support, which only does NVCC. This stops
            # cmake doing automatic things that derail our attempts to do this properly...
            set_source_files_properties(${_F} PROPERTIES
                LANGUAGE CXX
                COMPILE_OPTIONS "$<IF:$<BOOL:$<TARGET_PROPERTY:${TARGET},CUDA>>,${XCMAKE_CUDA_COMPILE_FLAGS},>"
            )
        else()
            if (DEFINED ENV{CLION_IDE})
                # Clion needs to be told what language header files are.
                if ("${FILE_EXT}" STREQUAL ".hpp")
                    set_source_files_properties(${_F} PROPERTIES
                        LANGUAGE CXX
                    )
                elseif("${FILE_EXT}" STREQUAL ".h")
                    set_source_files_properties(${_F} PROPERTIES
                        LANGUAGE C
                    )
                endif()
            endif()
        endif()
    endforeach()
endfunction()

function(add_library TARGET)
    cmake_parse_arguments(args "NOINSTALL;NOEXPORT" "" "" ${ARGN})

    _add_library(${TARGET} ${args_UNPARSED_ARGUMENTS})

    # Imported or interface targets definitely do not need to have their properties futzed with.
    ensure_not_imported(${TARGET})
    ensure_not_interface(${TARGET})

    apply_global_effects(${TARGET})
    fix_source_file_properties(${TARGET})

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
        endif()
        install(TARGETS ${TARGET} ${EXPORT_FLAGS} ARCHIVE DESTINATION lib LIBRARY DESTINATION lib)
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
    fix_source_file_properties(${TARGET})

    if (NOT args_NOINSTALL)
        install(TARGETS ${TARGET} RUNTIME DESTINATION bin)
    endif()
endfunction()

function (add_shell_script TARGET FILE)
    cmake_parse_arguments(args "NOINSTALL" "" "" ${ARGN})

    # Make the path absolute.
    if (NOT IS_ABSOLUTE ${FILE})
        set(FILE ${CMAKE_CURRENT_LIST_DIR}/${FILE})
    endif()

    # The "build" step is simply running shellcheck.
    set(STAMP_FILE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.stamp)

    add_custom_command(
        OUTPUT ${STAMP_FILE}
        COMMAND shellcheck -e SC2086,SC1117 ${FILE}
        COMMAND cmake -E touch ${STAMP_FILE}
        COMMENT "Shellcheck for ${TARGET}..."
        DEPENDS ${FILE}
        VERBATIM
    )

    add_custom_target(${TARGET} ALL
        DEPENDS ${STAMP_FILE}
    )

    if (NOT args_NOINSTALL)
        # Install the thing.
        install(PROGRAMS ${FILE} DESTINATION bin)
    endif()
endfunction()

# Forbid implicit "link by string". If you want it, do `target_link_libraries(myTarget PRIVATE RAW somelib)`. This
# avoids the common and _deeply obnoxious_ situation of typoing a target name and getting a raw link instead of the
# desired target link.
# In almost all cases, you want to use an IMPORTED target instead of a raw link anyway. If you want to add linker flags,
# use the
function (target_link_libraries TARGET)
    set(CURRENT_KEYWORD "")
    set(ALLOW_RAW FALSE)

    foreach (_ARG ${ARGN})
        # We can't sanitise generator expressions...
        string(GENEX_STRIP "${_ARG}" _ARG_SANITISED)
        if (NOT "${_ARG}" STREQUAL "${_ARG_SANITISED}")
            # If it contained a generator expression, skip it.
            continue()
        endif()

        if ("${_ARG}" STREQUAL "PRIVATE" OR
            "${_ARG}" STREQUAL "PUBLIC" OR
            "${_ARG}" STREQUAL "INTERFACE")
            set(CURRENT_KEYWORD ${_ARG})
            set(ALLOW_RAW FALSE)
        elseif ("${_ARG}" STREQUAL "RAW")
            set(ALLOW_RAW TRUE)
            remove_argument(FLAG ARGN RAW)
        else()
            if ("${CURRENT_KEYWORD}" STREQUAL "")
                message(FATAL_ERROR "Keywordless target_link_libraries() is not allowed.")
            elseif (NOT TARGET "${_ARG}" AND NOT "${ALLOW_RAW}")
                message(FATAL_ERROR
                    "Tried to link to nonexistent target \"${_ARG}\".\n"
                    "Did you typo your target name?\n"
                    "If you are trying to add linker flags, cmake now has `target_link_options()` for doing that.\n"
                    "If you are trying to link an external library by its raw name, use an IMPORTED target instead."
                )
            endif()
        endif()
    endforeach()

    _target_link_libraries(${TARGET} ${ARGN})
endfunction()

# Override target_sources to call fix_source_file_properties() again each time. Not exactly efficient, but it does
# the trick :D
# TODO: a more elaborate override that only iterates _new_ source files for the iteration. If we ever care enough about
#       performance...
# Note that cmake's default behaviour doesn't actually require true file names for input sources: it will automatically
# try with various file extensions. Replicating that behaviour is much of why doing the incremental version of this
# function would be a bit more fiddly than I can be bothered with just now.
function (target_sources TARGET)
    _target_sources(${TARGET} ${ARGN})

    fix_source_file_properties(${TARGET})
endfunction()
