# The ANSI format code escape symbol.
string(ASCII 27 ESC)

# Reset all formatting
set(Rst "${ESC}[0m")

set(Bold "${ESC}[1m")
set(BoldOff "${ESC}[21m")

# Dim/underlined/blink don't seem useful...

set(Invert "${ESC}[7m")
set(InvertOff "${ESC}[27m")

# See: https://misc.flogisoft.com/bash/tip_colors_and_formatting
set(Black "${ESC}[30m")
set(Red "${ESC}[31m")
set(Green "${ESC}[32m")
set(Yellow "${ESC}[33m")
set(Blue "${ESC}[34m")
set(Magenta "${ESC}[35m")
set(Cyan "${ESC}[36m")

set(Grey "${ESC}[90m")
set(DarkGrey "${ESC}[90m")
set(LightGrey "${ESC}[37m")

set(LightRed "${ESC}[91m")
set(LightGreen "${ESC}[92m")
set(LightYellow "${ESC}[93m")
set(LightBlue "${ESC}[94m")
set(LightMagenta "${ESC}[95m")
set(LightCyan "${ESC}[96m")

set(White "${ESC}[97m")

# Handy composite ones...
set(BoldRed "${ESC}[1;31m")
set(BoldGreen "${ESC}[1;32m")
set(BoldYellow "${ESC}[1;33m")
set(BoldBlue "${ESC}[1;34m")
set(BoldMagenta "${ESC}[1;35m")
set(BoldCyan "${ESC}[1;36m")
set(BoldGrey "${ESC}[1m${ESC}[90m")
set(BoldWhite "${ESC}[1;97m")

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

function(message MODE)
    # Select an appropriate default colour given the mode.
    if ("${MODE}" STREQUAL "STATUS")
        message_colour(${MODE} ${StatusColour} ${ARGN})
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
        message_colour(STATUS ${StatusColour} "${MODE}${ARGN}")
    endif()
endfunction()

macro (print_list LEVEL COLOUR LIST)
    foreach (_I ${LIST})
        message_colour(${LEVEL} ${COLOUR} ${_I})
    endforeach()
endmacro()
