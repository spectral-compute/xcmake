# Makes the second add_subdirectory of an equivalent thing a no-op. Handy for duplicated submodules.
macro(subdirectory_guard X)
    if (TARGET ${X}-GUARD)
        return()
    endif ()

    string(TOUPPER "${X}" SD_DIR_NAME)
    set(${SD_DIR_NAME}_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "")
    add_custom_target(${X}-GUARD)
    unset(SD_DIR_NAME)
endmacro()
