# Do add_subdirectory, but apply different values for some variables first, and restore their original values after.
# One use of this would be to get a subdirectory to default to static libraries without faffing with your own
# value of BUILD_SHARED_LIBS
#
# add_subdirectory_with(googletest -DBUILD_SHARED_LIBS=ON
function(add_subdirectory_with SUBDIR)
    set(VARS_AFFECTED "")
    foreach(ARG IN LISTS ARGN)
        string(REGEX REPLACE "-D([A-Za-z0-9_]+)=(.+)" "\\1" VNAME "${ARG}")
        string(REGEX REPLACE "-D([A-Za-z0-9_]+)=(.+)" "\\2" VVAL "${ARG}")

        list(APPEND VARS_AFFECTED ${VNAME})
        set(_OLD_${VNAME} ${VNAME})

        set(${VNAME} "${VVAL}")
    endforeach()

    add_subdirectory(${SUBDIR})

    foreach (ARG IN LISTS ARGN)
        set(${VNAME} ${_OLD_${VNAME}})
    endforeach()
endfunction()
