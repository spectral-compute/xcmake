# Stolen from https://cmake.org/Wiki/CMake_Performance_Tips#Use_an_include_guard
macro(IncludeGuard X)
    if (${${X}_INCLUDED})
        return()
    endif (${${X}_INCLUDED})

    set(${X}_INCLUDED true)
endmacro()
