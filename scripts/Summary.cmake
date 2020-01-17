include_guard(GLOBAL)

# Print a summary of the config so people realise if they screwed up.

function(print_target_config TARGET INDENT)
    ensure_not_object(${TARGET})
    ensure_not_imported(${TARGET})
    ensure_not_interface(${TARGET})

    get_target_property(T_TYPE ${TARGET} TYPE)
    if (${T_TYPE} STREQUAL "UTILITY")
        return()
    endif()

    message(GREEN "${INDENT} - ${TARGET} (${T_TYPE})")
    foreach (_P ${XCMAKE_TGT_PROPERTIES})
        get_target_property(PROP_VAL ${TARGET} ${_P})
        if (NOT ${PROP_VAL} STREQUAL "${XCMAKE_${_P}}")
            message(BOLD_BLUE "${INDENT}   * ${_P}: ${BOLD}${PROP_VAL}${BOLD_OFF}")
        endif ()
    endforeach ()
endfunction()

function(print_directory_summary DIR INDENT)
    set(NEWINDENT "${INDENT}    ")

    # Trim dir prefix
    string(REPLACE ${CMAKE_SOURCE_DIR} "" DIR_SUFF "${DIR}")
    get_filename_component(LAST_DIR ${DIR} NAME)

    message(YELLOW "${INDENT}/${LAST_DIR}")

    # Summarise the targets from this directory.
    get_directory_property(TARGET_LIST DIRECTORY ${DIR} BUILDSYSTEM_TARGETS)
    foreach (_T ${TARGET_LIST})
        print_target_config(${_T} "${NEWINDENT}")
    endforeach ()

    # Explore the next level.
    get_directory_property(DIR_LIST DIRECTORY ${DIR} SUBDIRECTORIES)
    foreach (_D ${DIR_LIST})
        print_directory_summary("${_D}" ${NEWINDENT})
    endforeach ()
endfunction()

function(PrintConfig)
    message(BOLD_YELLOW "\n\n======== CONFIGURATION SUMMARY =======\n")

    message(CYAN "Default target options (use -DXCMAKE_*=... to change):")
    message(BOLD_BLUE "TRIBBLE: ${BOLD}${XCMAKE_TRIBBLE}${BOLD_OFF}")
    foreach (_P ${XCMAKE_TGT_PROPERTIES})
        message(BOLD_BLUE "${_P}: ${BOLD}${XCMAKE_${_P}}${BOLD_OFF}")
    endforeach ()
    message("")

    # Explore the entire buildsystem looking for targets to describe.
    print_directory_summary(${CMAKE_SOURCE_DIR}/ "")
endfunction()

function(PrintCompiler)
    execute_process(COMMAND "${CMAKE_C_COMPILER}" "--version" OUTPUT_VARIABLE C_VERSION ERROR_QUIET OUTPUT_QUIET)
    execute_process(COMMAND "${CMAKE_CXX_COMPILER}" "--version" OUTPUT_VARIABLE CXX_VERSION ERROR_QUIET OUTPUT_QUIET)
    execute_process(COMMAND "${CMAKE_LINKER}" "--version" OUTPUT_VARIABLE LINKER_VERSION ERROR_QUIET OUTPUT_QUIET)
    string(REGEX REPLACE "\n.*" "" C_VERSION "${C_VERSION}")
    string(REGEX REPLACE "\n.*" "" CXX_VERSION "${CXX_VERSION}")

    message(BOLD_YELLOW "\n\n======== COMPILER SUMMARY =======\n")
    message(CYAN "C compiler: ${BOLD}${CMAKE_C_COMPILER}${BOLD_OFF}")
    message(CYAN "C compiler version: ${BOLD}${C_VERSION}${BOLD_OFF}")
    message(CYAN "C++ compiler: ${BOLD}${CMAKE_CXX_COMPILER}${BOLD_OFF}")
    message(CYAN "C++ compiler version: ${BOLD}${CXX_VERSION}${BOLD_OFF}")
    message(CYAN "Linker: ${BOLD}${CMAKE_LINKER}${BOLD_OFF}")
    message(CYAN "Linker version: ${BOLD}${LINKER_VERSION}${BOLD_OFF}")
endfunction()

add_exit_function(PrintConfig)
add_exit_function(PrintCompiler)
