include_guard(GLOBAL)
include(ExternalProj)

# On Windows, we need _CRT_DECLARE_NONSTDC_NAMES.
set(LIB_NAME z)
if (WIN32)
    set(LIB_NAME zlib)
    set(COMPILE_OPTIONS -D_CRT_DECLARE_NONSTDC_NAMES)
endif()

add_external_project(zlib_proj
    GIT_REPOSITORY    https://github.com/madler/zlib.git
    GIT_TAG           v1.2.12
    CMAKE_ARGS
        "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} ${COMPILE_OPTIONS}"
        "-DCMAKE_C_FLAGS=${CMAKE_CXX_FLAGS} ${COMPILE_OPTIONS}"
    STATIC_LIBRARIES
        ${LIB_NAME}
)

if (WIN32)
    add_library(z ALIAS ${LIB_NAME})
endif()
