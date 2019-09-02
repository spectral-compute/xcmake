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

    message_colour(STATUS Green "${INDENT} - ${TARGET} (${T_TYPE})")
    foreach (_P ${XCMAKE_TGT_PROPERTIES})
        get_target_property(PROP_VAL ${TARGET} ${_P})
        if (NOT ${PROP_VAL} STREQUAL "${XCMAKE_${_P}}")
            message_colour(STATUS BoldBlue "${INDENT}   * ${_P}: ${Bold}${PROP_VAL}${BoldOff}")
        endif ()
    endforeach ()
endfunction()

function(print_directory_summary DIR INDENT)
    set(NEWINDENT "${INDENT}    ")

    # Trim dir prefix
    string(REPLACE ${CMAKE_SOURCE_DIR} "" DIR_SUFF "${DIR}")
    get_filename_component(LAST_DIR ${DIR} NAME)

    message_colour(STATUS Yellow "${INDENT}/${LAST_DIR}")

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
    message_colour(STATUS BoldYellow "\n\n======== CONFIGURATION SUMMARY =======\n")

    message_colour(STATUS Cyan "Default target options (use -DXCMAKE_*=... to change):")
    foreach (_P ${XCMAKE_TGT_PROPERTIES})
        message_colour(STATUS BoldBlue "${_P}: ${Bold}${XCMAKE_${_P}}${BoldOff}")
    endforeach ()
    message("")

    # Explore the entire buildsystem looking for targets to describe.
    print_directory_summary(${CMAKE_SOURCE_DIR}/ "")
endfunction()

function(PrintCompiler)
    execute_process(COMMAND "${CMAKE_C_COMPILER}" "--version" OUTPUT_VARIABLE C_VERSION)
    execute_process(COMMAND "${CMAKE_CXX_COMPILER}" "--version" OUTPUT_VARIABLE CXX_VERSION)
    execute_process(COMMAND "${CMAKE_LINKER}" "--version" OUTPUT_VARIABLE LINKER_VERSION)
    string(REGEX REPLACE "\n.*" "" C_VERSION "${C_VERSION}")
    string(REGEX REPLACE "\n.*" "" CXX_VERSION "${CXX_VERSION}")

    message_colour(STATUS BoldYellow "\n\n======== COMPILER SUMMARY =======\n")
    message_colour(STATUS Cyan "C compiler: ${Bold}${CMAKE_C_COMPILER}${BoldOff}")
    message_colour(STATUS Cyan "C compiler version: ${Bold}${C_VERSION}${BoldOff}")
    message_colour(STATUS Cyan "C++ compiler: ${Bold}${CMAKE_CXX_COMPILER}${BoldOff}")
    message_colour(STATUS Cyan "C++ compiler version: ${Bold}${CXX_VERSION}${BoldOff}")
    message_colour(STATUS Cyan "Linker: ${Bold}${CMAKE_LINKER}${BoldOff}")
    message_colour(STATUS Cyan "Linker version: ${Bold}${LINKER_VERSION}${BoldOff}")
endfunction()

add_exit_function(PrintConfig)
add_exit_function(PrintCompiler)
