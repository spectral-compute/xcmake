# XCMAKE_INSTALL_EXTERNAL allows external files and directories specified on the cmake command line to be installed so
# they can be packaged by CPACK. The format is: "src1=dst1@component1;src2=dst2;...". Use "src=dst/" to copy the
# contents of src rather than src itself.
if (NOT XCMAKE_INSTALL_EXTERNAL)
    return()
endif()

foreach (SRC_DST_COMP IN LISTS XCMAKE_INSTALL_EXTERNAL)
    string(REGEX REPLACE "^([^=]*)=.*$" "\\1" SRC "${SRC_DST_COMP}")
    string(REGEX REPLACE "^[^=]*=([^@]*).*$" "\\1" DST "${SRC_DST_COMP}")

    if (SRC_DST_COMP MATCHES "@")
        string(REGEX REPLACE "^[^@]*@(.*)$" "\\1" COMP "${SRC_DST_COMP}")
        set(PROJECT_NAME "${COMP}" CACHE INTERNAL "")
    endif()

    if (NOT EXISTS "${SRC}")
        message(FATAL_ERROR "External path does not exist: ${SRC}")
    endif()
    if (IS_DIRECTORY "${SRC}")
        install(DIRECTORY "${SRC}" DESTINATION "${DST}")
    else()
        install(FILES "${SRC}" DESTINATION "${DST}")
    endif()
endforeach()
