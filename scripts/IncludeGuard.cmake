# Stolen from https://cmake.org/Wiki/CMake_Performance_Tips#Use_an_include_guard
macro(IncludeGuard X)
    if (DEFINED ${X}_INCLUDED)
        return()
    endif ()

    set(${X}_INCLUDED true)
endmacro()

# Makes the second add_subdirectory of an equivalent thing a no-op. Handy for duplicated submodules.
macro(SubdirectoryGuard X)
    if (TARGET ${X}-GUARD)
        return()
    endif ()

    set(${X}_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "")
    add_custom_target(${X}-GUARD)
endmacro()
