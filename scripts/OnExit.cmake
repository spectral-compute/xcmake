# Call the specified cmake function after completely running all CMake scripts.
#
# This relies on the undocumented fact that cmake checks CMAKE_BACKWARDS_COMPATIBILITY *after* running the scripts
# fully. It will certainly always check that varibale at some point, so new versions of cmake are unlikely to stop
# your hook from running at all: but it might stop happening at the end.
#
# Still, it does the job :D

macro(AddExitFunction NAME)
    # Amusing abuse of cache
    set(XCMAKE_EXIT_HOOK_HAS_RUN 0 CACHE INTERNAL "")
    function(${NAME}_EOFHOOK Variable Access)

        if (${Variable} STREQUAL CMAKE_BACKWARDS_COMPATIBILITY AND
        (${Access} STREQUAL UNKNOWN_READ_ACCESS OR ${Access} STREQUAL READ_ACCESS))
            if (${${NAME}_EOFHOOK_HAS_RUN})
                return()
            endif ()
            set(${NAME}_EOFHOOK_HAS_RUN 1 CACHE INTERNAL "")

            # Do the thing! :D
            dynamic_call(${NAME} "")
        endif ()
    endfunction()

    variable_watch(CMAKE_BACKWARDS_COMPATIBILITY ${NAME}_EOFHOOK)
endmacro()
