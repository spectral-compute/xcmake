# Routines for manipulating cmake argument lists.
# A common problem is a wish to pass argument lists - mutated - to some other function. This is
# surprisingly fiddly to do.

macro (remove_argument TYPE LIST NAME)
    # Remove the argument of the given name and type from the argument list named by "${LIST}".
    # TYPE can be "FLAG", "SINGLE", or "MULTI", and has meaning equivalent to that in
    # cmake_parse_arguments.
    # In the "MULTI" case, you must pass all other keys as an additional argument.

    # Find the key.
    list(FIND ${LIST} ${NAME} KEY_INDEX)

    # Remove it, if found. Otherwise stop.
    if (NOT ${KEY_INDEX} LESS 0)
        list(REMOVE_AT ${LIST} ${KEY_INDEX})

        if ("${TYPE}" STREQUAL "FLAG")
            # A flag is only a key - so we're done.
        elseif("${TYPE}" STREQUAL "SINGLE")
            # Remove the value - which must exist if the argument list is well-formed.
            list(REMOVE_AT ${LIST} ${KEY_INDEX})
        elseif("${TYPE}" STREQUAL "MULTI")
            set(KEYWORDS ${ARGN})

            # Keep removing values until we find something that's a key, or outside the list.
            list(LENGTH ${LIST} LIST_LENGTH)
            while(LIST_LENGTH GREATER KEY_INDEX)
                list(GET ${LIST} ${KEY_INDEX} NEXT_DELETION)

                list(FIND KEYWORDS "${NEXT_DELETION}" SENTINEL)
                if (SENTINEL GREATER_EQUAL 0)
                    list(GET KEYWORDS ${SENTINEL} WHAAAT)
                    break()
                endif()

                list(REMOVE_AT ${LIST} ${KEY_INDEX})
                list(LENGTH ${LIST} LIST_LENGTH)
            endwhile()

        else()
            message(FATAL_ERROR "Invalid argument type: ${TYPE}")
        endif()
    endif ()
endmacro()

macro(subtract_lists LIST REMOVE_ITEMS)
    foreach(_I IN LISTS ${REMOVE_ITEMS})
    endforeach()
endmacro()
