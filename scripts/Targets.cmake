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

# Try to add some compile options, but - for each one - only do so if the compiler accepts them.
# This is useful for things like warning or optimisation flags that aren't strictly required, but are
# preferred. It means your cmake script can work with lots of different compiler versions without the need
# to have complicated compiler version checks to see if the flag is really supported.
#
# The downside is that this function is quite slow, so if you use it a lot your cmake configure time will get
# rather long. Note, however, that the overhead is linear in the number of unique flags ever passed to this
# function, not in the number of targets multiplied by the number of flags.
#
# This accepts the same argument sas `target_compile_options`, except that you may only use one keyword at a time.
# Use multiple calls if you want to use multiple different keywords (or make the argument parsing more clever...)
function(target_optional_compile_options TARGET)
    if (XCMAKE_USE_NVCC)
        # You may not have nice things
        return()
    endif()

    cmake_parse_arguments("d" "BEFORE" "" "" ${ARGN})
    if (d_BEFORE)
        set(MAYBE_BEFORE BEFORE)
    else ()
        set(MAYBE_BEFORE "")
    endif ()

    # Pop the keyword off.
    list(GET d_UNPARSED_ARGUMENTS 0 KEYWORD)
    list(REMOVE_AT d_UNPARSED_ARGUMENTS 0)

    foreach (_F ${d_UNPARSED_ARGUMENTS})
        string(MAKE_C_IDENTIFIER ${_F} CACHE_VAR)
        check_cxx_compiler_flag(${_F} ${CACHE_VAR})

        if (${CACHE_VAR})
            target_compile_options(${TARGET} ${MAYBE_BEFORE} ${KEYWORD} ${_F})
        endif ()
    endforeach ()
endfunction()

# Get the name of the primary output file produced by the given target.
# This just picks between OUTPUT_NAME and LIBRARY_OUTPUT_NAME as appropriate.
function(get_output_name OUTVAR TARGET)
    get_target_property(TGT_TYPE ${TARGET} TYPE)

    # Output file prefix/suffix, determined by target type.
    set(PREFIX "")
    set(SUFFIX "")

    if (${TGT_TYPE} STREQUAL STATIC_LIBRARY)
        get_target_property(OUT_NAME ${TARGET} ARCHIVE_OUTPUT_NAME)
        set(PREFIX "${CMAKE_STATIC_LIBRARY_PREFIX}")
        set(SUFFIX "${CMAKE_STATIC_LIBRARY_SUFFIX}")
    elseif (${TGT_TYPE} STREQUAL SHARED_LIBRARY)
        get_target_property(OUT_NAME ${TARGET} LIBRARY_OUTPUT_NAME)
        set(PREFIX "${CMAKE_SHARED_LIBRARY_PREFIX}")
        set(SUFFIX "${CMAKE_SHARED_LIBRARY_SUFFIX}")
    elseif(${TGT_TYPE} STREQUAL EXECUTABLE)
        get_target_property(OUT_NAME ${TARGET} RUNTIME_OUTPUT_NAME)
        set(SUFFIX "${CMAKE_EXECUTABLE_SUFFIX}")
    else()
        message(FATAL_ERROR "Cannot get output name for target ${TARGET} of unsupported type ${TGT_TYPE}")
    endif()

    # Try the default output name property.
    if (NOT OUT_NAME)
        get_target_property(OUT_NAME ${TARGET} OUTPUT_NAME)
    endif()

    # CMake just uses the target name plus the prefixes/suffices if none of the properties are set.
    if (NOT OUT_NAME)
        set(OUT_NAME ${TARGET})
    endif()

    # Put it all together...
    set(${OUTVAR} "${PREFIX}${OUT_NAME}${SUFFIX}" PARENT_SCOPE)
endfunction()

# Get the directory in which the primary output file for a target will be generated.
function(get_output_dir OUTVAR TARGET)
    get_target_property(TGT_TYPE ${TARGET} TYPE)

    # There's a hierarchy of output directories for each type of target, and a global variable that's used as a
    # last resort. Let's start digging...
    if (${TGT_TYPE} STREQUAL STATIC_LIBRARY)
        get_target_property(OUT_DIR ${TARGET} ARCHIVE_OUTPUT_DIRECTORY)
    elseif (${TGT_TYPE} STREQUAL SHARED_LIBRARY)
        get_target_property(OUT_DIR ${TARGET} LIBRARY_OUTPUT_DIRECTORY)
    elseif(${TGT_TYPE} STREQUAL EXECUTABLE)
        get_target_property(OUT_DIR ${TARGET} RUNTIME_OUTPUT_DIRECTORY)
    else()
        message(FATAL_ERROR "Cannot get output directory for target ${TARGET} of unsupported type ${TGT_TYPE}")
    endif()

    if (NOT OUT_DIR)
        get_target_property(OUT_DIR ${TARGET} BINARY_DIR)
    endif()

    set(${OUTVAR} "${OUT_DIR}" PARENT_SCOPE)
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

    if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_optional_compile_options(${TARGET} BEFORE PRIVATE 
            /W4
        )
    else()
        # Diagnostic flags to be applied globally.
        target_optional_compile_options(${TARGET} BEFORE PRIVATE
            -Weverything # We like warnings.

            # Don't warn for using cool things.
            -Wno-c++98-c++11-c++14-c++17-compat-pedantic
            -Wno-c++98-compat-pedantic
            -Wno-c++11-compat-pedantic
            -Wno-c++14-compat-pedantic
            -Wno-c99-compat
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

            # We do actually want to use OpenMP sometimes...
            -Wno-source-uses-openmp

            # Warnings that appear to be broken.
            -Wno-weak-template-vtables           # Incorrectly warns about explicit instantiations in .cpp.
            -Wno-weak-vtables
            -Wno-assume                          # Incorrectly reports on the existence of side effects.

            -ftemplate-backtrace-limit=256       # We have some insane templates.
            -fconstexpr-backtrace-limit=256      # We have some insane constexpr functions, too.
            -fconstexpr-depth=65535              # Maximum constexpr call depth. We have a regex compiler, soo...
            -fconstexpr-steps=268435456          # Lots, but infinite loops still get diagnosed within a sensible amount of time.

            # Fortunately, Doxygen shouts at us anyway, and clang's diagnostic is quite false-positive-ful.
            -Wno-documentation-unknown-command
            -Wno-documentation  # https://gitlab.com/spectral-ai/engineering/cuda/platform/clang/issues/340

            # Make errors more readable in the presence of insane templates
            -fdiagnostics-show-template-tree
            -fdiagnostics-show-option
            -fdiagnostics-show-category=name

            # Emit an error if we accidentally code-gen jumbo-sized objects (even if these would be removed by optimization,
            # it's better not to generate them in the first place).
            -fmax-data-global-size=67108864
            -fmax-data-local-size=1048576
        )
    endif()


    # Work around a bug in Ninja that prevents coloured diagnostics by default, which they refuse to fix:
    # https://github.com/ninja-build/ninja/issues/174
    if (${CMAKE_GENERATOR} STREQUAL "Ninja")
        target_optional_compile_options(${TARGET} BEFORE PRIVATE -fdiagnostics-color=always)
    endif()

    # If building for Windows...
    if (WIN32)
        target_link_options(${TARGET} PRIVATE
            /OPT:NOREF
        )

        if (CMAKE_CXX_COMPILER_ID MATCHES MSVC)
        else()
            target_compile_options(${TARGET} PRIVATE
                # No, LLVM, we don't want you to attempt to emulate bugs in the Microsoft compiler.
                -fno-ms-compatibility

                # TODO: Refactor to using new functions where we can, and turning off the warning locally instead
                -Wno-deprecated
            )
        endif()

        if (${CMAKE_BUILD_TYPE} STREQUAL "Debug")
            set(DEBUG_LEVEL_VAL 2)
        else()
            # No bounds checks on STL containers, since they don't compile in device binaries.
            # This seems to be a quirk of the MSVC STL.
            set(DEBUG_LEVEL_VAL 0)
        endif()

        target_compile_definitions(${TARGET} PRIVATE
            # Stop Windows including more headers than needed
            -DWIN32_LEAN_AND_MEAN
            -D_CONTAINER_DEBUG_LEVEL=${DEBUG_LEVEL_VAL}
            -D_ITERATOR_DEBUG_LEVEL=${DEBUG_LEVEL_VAL}
        )
    endif()

    # If the compiler accepts an MSVC-like command-line...
    # This will be true for `clang-cl`, `msvc`, and a few others.
    if (MSVC)
        target_compile_options(${TARGET} PRIVATE
            # We use clang-cl on Windows instead of clang++, so we need a few clang-cl flags
            $<$<COMPILE_LANGUAGE:CXX>:/EHs> # CL error handling mode (s == synchronous)

            # Suppress buffer overrun detection, except in assert builds.
            $<IF:$<BOOL:$<TARGET_PROPERTY:ASSERTIONS>>,,$<$<COMPILE_LANGUAGE:CXX>:/GS->>
        )
        # Use Microsoft's multithread-compatible dynamic libraries to avoid copying the whole STL into our libraries
        # This is _technically_ defaulted to by /MT
        set_target_properties(${TARGET}
            PROPERTIES 
            MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
        )
    endif ()
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

    # Exclude windows DLL functionality when compiling for device
    # Indented poorly so the resulting output is nice
    set(DLL_EXCLUDE
"\n#if defined(_WIN32) && defined(__CUDA__) && defined(__CUDA_ARCH__) \n\
    #undef ${BASE_NAME}_EXPORT \n\
    #define ${BASE_NAME}_EXPORT \n\
#endif\n"
    )

    # Generate the header.
    generate_export_header(${TARGET} BASE_NAME "${BASE_NAME}" EXPORT_FILE_NAME "${EXPORT_HDR_PATH}" CUSTOM_CONTENT_FROM_VARIABLE DLL_EXCLUDE)

    # Install the header.
    if (NOT args_NOINSTALL)
        install(FILES "${EXPORT_HDR_PATH}" DESTINATION "./include/${EXPORT_DIRECTORY_NAME}")
    endif()

    # Fix IDE indexing of the header.
    target_include_directories(${TARGET} PRIVATE ${EXPORT_HEADER_DIR})
endfunction()

function(fix_source_file_properties TARGET)
    # Never, ever tell cmake that anything is CUDA. We do it our own way, unless nvcc is enabled.
    get_target_property(SOURCE_FILES ${TARGET} SOURCES)

    # This probably isn't fast.
    foreach(_F in ${SOURCE_FILES})
        get_source_file_property(CUR_LANG "${_F}" LANGUAGE)
        get_filename_component(FILE_EXT "${_F}" EXT)

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

        if (NOT XCMAKE_USE_NVCC)
            if ((${CUR_LANG} STREQUAL "CUDA") OR ("${FILE_EXT}" STREQUAL ".cu") OR ("${FILE_EXT}" STREQUAL ".cuh"))
                # This disables cmake's built-in CUDA support, which only does NVCC. This stops
                # cmake doing automatic things that derail our attempts to do this properly...
                get_target_property(CUDA_TU_FLAGS CUDA_FLAGS INTERFACE_COMPILE_OPTIONS)
                set_source_files_properties(${_F} PROPERTIES
                    LANGUAGE CXX
                    COMPILE_OPTIONS "$<IF:$<BOOL:$<TARGET_PROPERTY:${TARGET},CUDA>>,${CUDA_TU_FLAGS},>"
                )
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

    # Add yourself as a dll search path for users.
    set_property(TARGET ${TARGET} APPEND PROPERTY INTERFACE_DLL_SEARCH_PATHS "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")

    if (NOT args_NOINSTALL)
        if (NOT args_NOEXPORT)
            set(EXPORT_FLAGS EXPORT ${PROJECT_NAME})
        endif()
        install(TARGETS ${TARGET} ${EXPORT_FLAGS}
            ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
            LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
            RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
        )
    endif()
endfunction()

function(add_executable TARGET)
    cmake_parse_arguments(args "NOINSTALL" "" "" ${ARGN})

    _add_executable(${TARGET} ${args_UNPARSED_ARGUMENTS})

    # Don't screw with settings if it's imported
    ensure_not_imported(${TARGET})

    # On implib platforms, create a command that will create symbolic links to
    # all DLL dependencies at the install destination
    handle_symlinks(${TARGET})

    # Apply standard settings and properties
    apply_default_standard_properties(${TARGET})
    apply_default_properties(${TARGET})
    apply_effect_groups(${TARGET})
    apply_global_effects(${TARGET})
    fix_source_file_properties(${TARGET})

    if (NOT args_NOINSTALL)
        install(TARGETS ${TARGET} RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
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
        COMMAND ${CMAKE_COMMAND} -E touch ${STAMP_FILE}
        COMMENT "Shellcheck for ${TARGET}..."
        DEPENDS ${FILE}
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
function(target_link_libraries TARGET)
    set(CURRENT_KEYWORD "")
    set(ALLOW_RAW FALSE)

    foreach(_ARG ${ARGN})
        # We can't sanitise generator expressions...
        string(GENEX_STRIP "${_ARG}" _ARG_SANITISED)

        # If it contained a generator expression, skip it.
        if(NOT "${_ARG}" STREQUAL "${_ARG_SANITISED}")
            # We still want to process DLL path interface property though
            propogate_dll_paths(${CURRENT_KEYWORD} ${TARGET} ${_ARG})
            continue()
        endif()

        if("${_ARG}" STREQUAL "PRIVATE" OR
            "${_ARG}" STREQUAL "PUBLIC" OR
            "${_ARG}" STREQUAL "INTERFACE")
            set(CURRENT_KEYWORD ${_ARG})
            set(ALLOW_RAW FALSE)
        elseif("${_ARG}" STREQUAL "RAW")
            set(ALLOW_RAW TRUE)
            remove_argument(FLAG ARGN RAW)
        else()
            if("${CURRENT_KEYWORD}" STREQUAL "")
                message(FATAL_ERROR "Keywordless target_link_libraries() is not allowed.")
            elseif(NOT TARGET "${_ARG}" AND NOT "${ALLOW_RAW}")
                message(FATAL_ERROR
                    "Tried to link to nonexistent target \"${_ARG}\".\n"
                    "Did you typo your target name?\n"
                    "If you are trying to add linker flags, cmake now has `target_link_options()` for doing that.\n"
                    "If you are trying to link an external library by its raw name, use an IMPORTED target instead."
                )
            elseif(NOT ${ALLOW_RAW})
                propogate_dll_paths(${CURRENT_KEYWORD} ${TARGET} ${_ARG})
            endif()
        endif()
    endforeach()

    _target_link_libraries(${TARGET} ${ARGN})
endfunction()

function(propogate_dll_paths KEYWORD TARGET LINKED)
    set(LINKED_PATHS_CONTENT "")

    # Use IMPORTED_LOCATION as INTERFACE_DLL_SEARCH_PATHS for non-INTERFACE, IMPORTED targets
    if (TARGET ${LINKED})
        get_target_property(LINKED_IMPORTED ${LINKED} IMPORTED)
        get_target_property(TARGET_TYPE ${LINKED} TYPE)

        # IMPORTED_LOCATION is not on the INTERFACE property whitelist
        if (LINKED_IMPORTED AND NOT ${TARGET_TYPE} STREQUAL "INTERFACE_LIBRARY")
            get_target_property(LINKED_LOCATION ${LINKED} IMPORTED_LOCATION)
            get_filename_component(LINKED_PATHS_CONTENT "${LINKED_LOCATION}" DIRECTORY)
        endif()
    endif()

    # Propagate the inteface property.
    list(APPEND LINKED_PATHS_CONTENT "$<GENEX_EVAL:$<$<BOOL:${LINKED}>:$<TARGET_PROPERTY:${LINKED},INTERFACE_DLL_SEARCH_PATHS>>>")

    # Interface-property progation as usual.
    if (NOT "${KEYWORD}" STREQUAL "INTERFACE")
        set_property(TARGET ${TARGET} APPEND PROPERTY DLL_SEARCH_PATHS ${LINKED_PATHS_CONTENT})
    endif()
    if (NOT "${KEYWORD}" STREQUAL "PRIVATE")
        set_property(TARGET ${TARGET} APPEND PROPERTY INTERFACE_DLL_SEARCH_PATHS ${LINKED_PATHS_CONTENT})
    endif()
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

# This function adds a build-time command to run an external script finding DLLs
function(handle_symlinks TARGET)
    if(NOT XCMAKE_IMPLIB_PLATFORM)
        return()
    endif()

    include(FindThreads)

    # Get the path to the executable's eventual directory
    get_output_dir(EXE_DIR ${TARGET})
    get_output_name(EXE_NAME ${TARGET})

    add_custom_command(
        TARGET ${TARGET}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -P "${XCMAKE_TOOLS_DIR}/SymLink.cmake"
            "${EXE_DIR}/${EXE_NAME}"
            "$<GENEX_EVAL:$<TARGET_PROPERTY:${TARGET},DLL_SEARCH_PATHS>>"
        COMMENT "Creating symbolic links for ${EXE_DIR}/${TARGET}.exe"
    )
endfunction()
