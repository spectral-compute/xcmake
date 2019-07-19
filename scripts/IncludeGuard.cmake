# Makes the second add_subdirectory of an equivalent thing a no-op. Handy for duplicated submodules.
macro(SubdirectoryGuard X)
    if (TARGET ${X}-GUARD)
        return()
    endif ()

    set(${X}_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "")
    add_custom_target(${X}-GUARD)
endmacro()
