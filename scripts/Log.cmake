# The ANSI format code escape symbol.
string(ASCII 27 ESC)

# Macro for defining a formatting code. Sets it to empty-string if colour isn't supported
macro(defineFormatCode NAME VALUE)
    # Clion doesn't do coloured cmake output, alas.
    if ($ENV{CLION_IDE})
        set(${NAME} "")
    else()
        set(${NAME} ${VALUE})
    endif()
endmacro()

# Reset all formatting
defineFormatCode(Rst "${ESC}[0m")

defineFormatCode(Bold "${ESC}[1m")
defineFormatCode(BoldOff "${ESC}[21m")

# Dim/underlined/blink don't seem useful...

defineFormatCode(Invert "${ESC}[7m")
defineFormatCode(InvertOff "${ESC}[27m")

# See: https://misc.flogisoft.com/bash/tip_colors_and_formatting
defineFormatCode(Black "${ESC}[30m")
defineFormatCode(Red "${ESC}[31m")
defineFormatCode(Green "${ESC}[32m")
defineFormatCode(Yellow "${ESC}[33m")
defineFormatCode(Blue "${ESC}[34m")
defineFormatCode(Magenta "${ESC}[35m")
defineFormatCode(Cyan "${ESC}[36m")

defineFormatCode(Grey "${ESC}[90m")
defineFormatCode(DarkGrey "${ESC}[90m")
defineFormatCode(LightGrey "${ESC}[37m")

defineFormatCode(LightRed "${ESC}[91m")
defineFormatCode(LightGreen "${ESC}[92m")
defineFormatCode(LightYellow "${ESC}[93m")
defineFormatCode(LightBlue "${ESC}[94m")
defineFormatCode(LightMagenta "${ESC}[95m")
defineFormatCode(LightCyan "${ESC}[96m")

defineFormatCode(White "${ESC}[97m")

# Handy composite ones...
defineFormatCode(BoldRed "${ESC}[1;31m")
defineFormatCode(BoldGreen "${ESC}[1;32m")
defineFormatCode(BoldYellow "${ESC}[1;33m")
defineFormatCode(BoldBlue "${ESC}[1;34m")
defineFormatCode(BoldMagenta "${ESC}[1;35m")
defineFormatCode(BoldCyan "${ESC}[1;36m")
defineFormatCode(BoldGrey "${ESC}[1m${ESC}[90m")
defineFormatCode(BoldWhite "${ESC}[1;97m")

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
    foreach (_I ${LIST})
        message_colour(${LEVEL} ${COLOUR} ${_I})
    endforeach()
endmacro()
