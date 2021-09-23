# The ANSI format code escape symbol.
string(ASCII 27 ESC)

set(ALL_COLOURS "")

# Macro for defining a formatting code. Sets it to empty-string if colour isn't supported
macro(define_format_code NAME VALUE)
    # Clion doesn't do coloured cmake output, alas.
    if (DEFINED ENV{CLION_IDE})
        set(${NAME} "")
    else()
        set(${NAME} ${VALUE})
    endif()

    list(APPEND ALL_COLOURS ${NAME})
endmacro()

# Reset all formatting
define_format_code(RST "${ESC}[0m")

define_format_code(BOLD "${ESC}[1m")
define_format_code(BOLD_OFF "${ESC}[21m")

# Dim/underlined/blink don't seem useful...

define_format_code(INVERT "${ESC}[7m")
define_format_code(INVERT_OFF "${ESC}[27m")

# See: https://misc.flogisoft.com/bash/tip_colors_and_formatting
define_format_code(BLACK "${ESC}[30m")
define_format_code(RED "${ESC}[31m")
define_format_code(GREEN "${ESC}[32m")
define_format_code(YELLOW "${ESC}[33m")
define_format_code(BLUE "${ESC}[34m")
define_format_code(MAGENTA "${ESC}[35m")
define_format_code(CYAN "${ESC}[36m")

define_format_code(GREY "${ESC}[90m")
define_format_code(DARK_GREY "${ESC}[90m")
define_format_code(LIGHT_GREY "${ESC}[37m")

define_format_code(LIGHT_RED "${ESC}[91m")
define_format_code(LIGHT_GREEN "${ESC}[92m")
define_format_code(LIGHT_YELLOW "${ESC}[93m")
define_format_code(LIGHT_BLUE "${ESC}[94m")
define_format_code(LIGHT_MAGENTA "${ESC}[95m")
define_format_code(LIGHT_CYAN "${ESC}[96m")

define_format_code(WHITE "${ESC}[97m")

# Handy composite ones...
define_format_code(BOLD_RED "${ESC}[1;31m")
define_format_code(BOLD_GREEN "${ESC}[1;32m")
define_format_code(BOLD_YELLOW "${ESC}[1;33m")
define_format_code(BOLD_BLUE "${ESC}[1;34m")
define_format_code(BOLD_MAGENTA "${ESC}[1;35m")
define_format_code(BOLD_CYAN "${ESC}[1;36m")
define_format_code(BOLD_GREY "${ESC}[1m${ESC}[90m")
define_format_code(BOLD_WHITE "${ESC}[1;97m")

# Default colours for each loglevel
set(STATUSColour BOLD_WHITE)
set(WARNINGColour BOLD_YELLOW)
set(AUTHOR_WARNINGColour BOLD_YELLOW)
set(SEND_ERRORColour BOLD_RED)
set(FATAL_ERRORColour BOLD_RED)
set(DEPRECATIONColour BOLD_BLUE)
set(CHECK_STARTColour BLUE)
set(CHECK_PASSColour GREEN)
set(CHECK_FAILColour YELLOW)

# Implementation detail.
function(contextual_format OUT MSG)
    # Pick a default message colour based on a guess about message type.
    # This is handy for assigning meaningful colours to CMake's default messages.
    if ("${MSG}" MATCHES "^Found")
        set(${OUT} YELLOW PARENT_SCOPE)
    elseif (("${MSG}" MATCHES "^Looking for") OR
            ("${MSG}" MATCHES "^Performing Test") OR
            ("${MSG}" MATCHES "^Detecting"))
        set(${OUT} GREY PARENT_SCOPE)
    else()
        set(${OUT} BOLD_WHITE PARENT_SCOPE)
    endif()
endfunction()

# Implementation detail.
function(colour_log_impl LOG_LEVEL COLOUR)
    set(CHOSEN_COLOUR ${COLOUR})

    if (${ARGC} LESS 3)
        # No colour was provided. The colour is actually the message.
        set(CHOSEN_COLOUR "")
        set(ARGN "${COLOUR};${ARGN}")
    else()
        # Is the colour invalid? If so, it's not a colour, so drop it.
        string(TOUPPER "${CHOSEN_COLOUR}" CHOSEN_COLOUR)
        list(FIND ALL_COLOURS "${CHOSEN_COLOUR}" COLOUR_VALID)
        if (COLOUR_VALID EQUAL -1)
            set(CHOSEN_COLOUR "")
            set(ARGN "${COLOUR};${ARGN}")
        endif()
    endif()

    # Try assigning a default colour.
    if (CHOSEN_COLOUR STREQUAL "")
        set(CHOSEN_COLOUR ${${LOG_LEVEL}Colour})

        if (${LOG_LEVEL} STREQUAL STATUS)
            contextual_format(CHOSEN_COLOUR "${ARGN}")
        endif()
    endif()

    # Finally print it, replicating cmake's weird "concat all the arguments" behaviour.
    set(MSG "${${CHOSEN_COLOUR}}")
    foreach (M ${ARGN})
        set(MSG "${MSG}${M}")
    endforeach ()
    set(MSG "${MSG}${RST}")

    _message(${LOG_LEVEL} ${MSG})
endfunction()

# Log at particular levels, with optional colour.
# The COLOUR argument is always optional, with a sensible default being chosen. If only one argument is given, it is
# assumed not to be a colour, naturally.
function(warn COLOUR)
    colour_log_impl(WARNING ${COLOUR} ${ARGN})
endfunction()

function(deprecated COLOUR)
    colour_log_impl(DEPRECATION ${COLOUR} ${ARGN})
endfunction()

function(error COLOUR)
    colour_log_impl(SEND_ERROR ${COLOUR} ${ARGN})
endfunction()

function(fatal_error COLOUR)
    colour_log_impl(FATAL_ERROR ${COLOUR} ${ARGN})
endfunction()

# `message()` is overridden in a backward-compatible way.
# Some examples:

# ```{.cmake}
#   # These two are equivalent.
#   message(BLUE "Hello, world")
#   message(STATUS BLUE "Hello, world")
#
#   # These foour are equivalent.
#   message(FATAL_ERROR "Hello, world")
#   message(FATAL_ERROR BOLD_RED "Hello, world")
#   fatal_error("Hello, world")
#   fatal_error(BOLD_RED "Hello, world")
# ```
function(message MODE)
    string(TOUPPER "${MODE}" UP_MODE)
    # If the first argument is recognised as a log-level, consume it as one. Otherwise, just delegate everything to
    # the other function (which is going to try to interpret it as a colour instead).
    if ("${UP_MODE}" STREQUAL STATUS)
        colour_log_impl(STATUS ${ARGN})
    elseif("${UP_MODE}" STREQUAL WARNING)
        colour_log_impl(WARNING ${ARGN})
    elseif("${UP_MODE}" STREQUAL AUTHOR_WARNING)
        colour_log_impl(AUTHOR_WARNING ${ARGN})
    elseif("${UP_MODE}" STREQUAL SEND_ERROR)
        colour_log_impl(SEND_ERROR ${ARGN})
    elseif("${UP_MODE}" STREQUAL FATAL_ERROR)
        colour_log_impl(FATAL_ERROR ${ARGN})
    elseif("${UP_MODE}" STREQUAL DEPRECATION)
        colour_log_impl(DEPRECATION ${ARGN})
    elseif("${UP_MODE}" STREQUAL CHECK_START)
        colour_log_impl(CHECK_START ${ARGN})
    elseif("${UP_MODE}" STREQUAL CHECK_PASS)
        colour_log_impl(CHECK_PASS ${ARGN})
    elseif("${UP_MODE}" STREQUAL CHECK_FAIL)
        colour_log_impl(CHECK_FAIL ${ARGN})
    else()
        colour_log_impl(STATUS "${MODE}" ${ARGN})
    endif()
endfunction()

function(warning BACKTRACE MSG)
    if (BACKTRACE)
        message(WARNING "Warning${RST}: ${MSG}")
    else()
        message(BOLD_YELLOW "Warning${RST}: ${MSG}")
    endif()

    if (XCMAKE_ACCUMULATED_WARNINGS)
        set(XCMAKE_ACCUMULATED_WARNINGS "${XCMAKE_ACCUMULATED_WARNINGS}" "${MSG}" CACHE INTERNAL "")
    else()
        set(XCMAKE_ACCUMULATED_WARNINGS "${MSG}" CACHE INTERNAL "")
    endif()
endfunction()

macro (print_list LEVEL COLOUR LIST)
    foreach (_I ${${LIST}})
        message(${LEVEL} ${COLOUR} ${_I})
    endforeach()
    message("")
endmacro()
