# Call the specified cmake function after completely running all CMake scripts.
#
# This relies on the undocumented fact that cmake checks CMAKE_BACKWARDS_COMPATIBILITY *after* running the scripts
# fully. It will certainly always check that variable at some point, so new versions of cmake are unlikely to stop
# your hook from running at all: but it might stop happening at the end. Since that variable has been deprecated for
# years (in fact it's very nearly the *first* thing to have been deprecated by cmake), it is very unlikely a user is
# going to touch the variable and trigger the variable monitor early (and if they do, we have much bigger problems
# because it implies they're using cmake <= 2.4).
#
# Still, it does the job :D

macro(AddExitFunction NAME)
    # Amusing abuse of cache
    set(${NAME}_EOFHOOK_HAS_RUN 0 CACHE INTERNAL "")
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
