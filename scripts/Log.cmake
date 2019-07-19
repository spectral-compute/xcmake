# The ANSI format code escape symbol.
string(ASCII 27 ESC)

# Macro for defining a formatting code. Sets it to empty-string if colour isn't supported
macro(define_format_code NAME VALUE)
    # Clion doesn't do coloured cmake output, alas.
    if (DEFINED ENV{CLION_IDE})
        set(${NAME} "")
    else()
        set(${NAME} ${VALUE})
    endif()
endmacro()

# Reset all formatting
define_format_code(Rst "${ESC}[0m")

define_format_code(Bold "${ESC}[1m")
define_format_code(BoldOff "${ESC}[21m")

# Dim/underlined/blink don't seem useful...

define_format_code(Invert "${ESC}[7m")
define_format_code(InvertOff "${ESC}[27m")

# See: https://misc.flogisoft.com/bash/tip_colors_and_formatting
define_format_code(Black "${ESC}[30m")
define_format_code(Red "${ESC}[31m")
define_format_code(Green "${ESC}[32m")
define_format_code(Yellow "${ESC}[33m")
define_format_code(Blue "${ESC}[34m")
define_format_code(Magenta "${ESC}[35m")
define_format_code(Cyan "${ESC}[36m")

define_format_code(Grey "${ESC}[90m")
define_format_code(DarkGrey "${ESC}[90m")
define_format_code(LightGrey "${ESC}[37m")

define_format_code(LightRed "${ESC}[91m")
define_format_code(LightGreen "${ESC}[92m")
define_format_code(LightYellow "${ESC}[93m")
define_format_code(LightBlue "${ESC}[94m")
define_format_code(LightMagenta "${ESC}[95m")
define_format_code(LightCyan "${ESC}[96m")

define_format_code(White "${ESC}[97m")

# Handy composite ones...
define_format_code(BoldRed "${ESC}[1;31m")
define_format_code(BoldGreen "${ESC}[1;32m")
define_format_code(BoldYellow "${ESC}[1;33m")
define_format_code(BoldBlue "${ESC}[1;34m")
define_format_code(BoldMagenta "${ESC}[1;35m")
define_format_code(BoldCyan "${ESC}[1;36m")
define_format_code(BoldGrey "${ESC}[1m${ESC}[90m")
define_format_code(BoldWhite "${ESC}[1;97m")

# Default colours for each loglevel
set(StatusColour BoldWhite)
set(WarningColour BoldYellow)
set(ErrorColour BoldRed)
set(DeprecationColour BoldBlue)

function(message_colour LEVEL COLOUR)
    # Build the output message by colourising the arguments. This mirrors cmake's message()
    # behaviour which concats its arguments. Relying on that seems quite odd, though...
    set(MSG "${${COLOUR}}")
    foreach (M ${ARGN})
        set(MSG "${MSG}${M}")
    endforeach()
    set(MSG "${MSG}${Rst}")

    _message(${LEVEL} ${MSG})
endfunction()

function(contextual_format OUT MSG)
    # Pick a default message colour based on a guess about message type.
    # This is handy for assigning meaningful colours to CMake's default messages.
    if ("${MSG}" MATCHES "^Found")
        set(${OUT} Yellow PARENT_SCOPE)
    elseif (("${MSG}" MATCHES "^Looking for") OR
            ("${MSG}" MATCHES "^Performing Test") OR
            ("${MSG}" MATCHES "^Detecting"))
        set(${OUT} Grey PARENT_SCOPE)
    else()
        set(${OUT} BoldWhite PARENT_SCOPE)
    endif()
endfunction()

function(message MODE)
    # Select an appropriate default colour given the mode.
    if ("${MODE}" STREQUAL "STATUS")
        contextual_format(MSG_COL "${ARGN}")
        message_colour(${MODE} ${MSG_COL} ${ARGN})
    elseif ("${MODE}" STREQUAL "WARNING")
        message_colour(${MODE} ${WarningColour} ${ARGN})
    elseif ("${MODE}" STREQUAL "AUTHOR_WARNING")
        message_colour(${MODE} ${WarningColour} ${ARGN})
    elseif ("${MODE}" STREQUAL "SEND_ERROR")
        message_colour(${MODE} ${ErrorColour} ${ARGN})
    elseif ("${MODE}" STREQUAL "FATAL_ERROR")
        message_colour(${MODE} ${ErrorColour} ${ARGN})
    elseif ("${MODE}" STREQUAL "DEPRECATION")
        message_colour(${MODE} ${DeprecationColour} ${ARGN})
    else()
        # Same colour as the STATUS case, but argument consumption is subtly different...
        contextual_format(MSG_COL "${ARGN}")
        message_colour(STATUS ${MSG_COL} "${MODE}${ARGN}")
    endif()
endfunction()

macro (print_list LEVEL COLOUR LIST)
    foreach (_I ${${LIST}})
        message_colour(${LEVEL} ${COLOUR} ${_I})
    endforeach()
    message("")
endmacro()
