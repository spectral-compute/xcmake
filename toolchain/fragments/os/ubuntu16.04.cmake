if ("${XCMAKE_ARCH}" STREQUAL "x86_64")
    set(XCMAKE_CTNG_VENDOR ubuntu16.04)
endif()

include(${CMAKE_CURRENT_LIST_DIR}/common/linux.cmake)
