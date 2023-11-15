# Find the header dependencies of a C++ source/header file.
#
# This is useful, for example, to restrict the set of installed headers to only those needed for a particular use-case.
# System headers are not included.
#
# Flags:
#   INCLUDE_SELF Include the sources as part of the result. Note that a source will be included anyway if it's a
#                dependency of one of the other sources. It will be excluded if it it's not in the RELATIVE directory
#                (if given).
#
# Single-value arguments:
#   RESULT The name of the variable to write the list of dependencies to.
#   RELATIVE If set, the resulting list will be relative to this location. Only headers that are in this location will
#            be returned.
#   TARGET Extract include directories, macrodefs, etc. from the given target. Generator expressions are ignored, as are
#          macros/incdirs added after the call to this function.
#
# Multi-value arguments:
#   SOURCES The list of source files to get dependencies for. The result is the union of the dependencies of all the
#           sources.
#   INCLUDE_PATHS Where to look for the dependencies. It is an error if a header cannot be found.
#   DEFINES A list of defines (with the -D) to be given to the compiler. This affects the dependencies if some of the
#           includes are wrapped in #ifdefs.
function (get_cpp_dependencies)
    cmake_parse_arguments("args" "INCLUDE_SELF" "RELATIVE;RESULT;TARGET" "SOURCES;INCLUDE_PATHS;DEFINES" ${ARGN})

    if (TARGET ${args_TARGET})
        get_target_property(INCS ${args_TARGET} INCLUDE_DIRECTORIES)
        get_target_property(IINCS ${args_TARGET} INTERFACE_INCLUDE_DIRECTORIES)
        foreach (F IN LISTS IINCS INCS)
            if (F) # Omit "NOTFOUND"s
                list(APPEND args_INCLUDE_PATHS ${F})
            endif()
        endforeach ()
    endif()

    print_list(STATUS RED args_INCLUDE_PATHS)

    # Figure out the arguments that apply for each source file.
    set(args -MM ${args_DEFINES})
    foreach (path ${args_INCLUDE_PATHS})
        list(APPEND args -I${path})
    endforeach()

    # Run the compiler's dependency checker for each source.
    set(deps "")
    foreach (source ${args_SOURCES})
        # Run the compiler.
        execute_process(COMMAND ${CMAKE_CXX_COMPILER} ${args} ${source}
                        RESULT_VARIABLE cmd_result OUTPUT_VARIABLE source_deps)
        if (cmd_result)
            fatal_error("Could not get dependencies of ${source}")
        endif()

        # Turn the output into a semicolon-separated list.
        string(REGEX REPLACE "\n" "" source_deps "${source_deps}")
        string(REGEX REPLACE " *\\\\ *" ";" source_deps "${source_deps}")

        # The first item in the list is a fictional object file.
        list(POP_FRONT source_deps)

        # The next item in the list is the source itself.
        if (NOT args_INCLUDE_SELF)
            list(POP_FRONT source_deps)
        endif()

        # Accumulate the dependencies as absolute paths.
        foreach (dep ${source_deps})
            get_filename_component(dep ${dep} ABSOLUTE)
            list(APPEND deps ${dep})
        endforeach()
    endforeach()

    # Sort and filter to be unique.
    list(SORT deps)
    list(REMOVE_DUPLICATES deps)

    # We probably want cmake to rerun to get this list if any of the dependencies change.
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${args_SOURCES} ${deps})

    # If the result is to be relative to some path, then remove the results that are not within that path, and make the
    # rest relative.
    if (args_RELATIVE)
        get_filename_component(args_RELATIVE ${args_RELATIVE} ABSOLUTE)
        string(REGEX REPLACE "/+$" "/" args_RELATIVE "${args_RELATIVE}/")
        string(LENGTH ${args_RELATIVE} rel_length)

        set(absolute_deps ${deps})
        set(deps "")
        foreach (dep ${absolute_deps})
            string(FIND ${dep} ${args_RELATIVE} rel_idx)
            if (NOT "${rel_idx}" EQUAL "0")
                continue()
            endif()

            string(SUBSTRING ${dep} ${rel_length} -1 rel_dep)
            list(APPEND deps ${rel_dep})
        endforeach()
    endif()

    # Return the result.
    set(${args_RESULT} ${deps} PARENT_SCOPE)
endfunction()
