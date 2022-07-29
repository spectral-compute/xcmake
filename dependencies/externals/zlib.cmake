include_guard(GLOBAL)
include(ExternalProj)

# On Windows, we need _CRT_DECLARE_NONSTDC_NAMES.
if (WIN32)
    set(COMPILE_OPTIONS -D_CRT_DECLARE_NONSTDC_NAMES)
endif()

add_external_project(zlib_proj
    GIT_REPOSITORY    https://github.com/madler/zlib.git
    GIT_TAG           v1.2.12
    CMAKE_ARGS
        "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} ${COMPILE_OPTIONS}"
        "-DCMAKE_C_FLAGS=${CMAKE_CXX_FLAGS} ${COMPILE_OPTIONS}"
        "-DCMAKE_BUILD_TYPE=Release"
    STATIC_LIBRARIES
        z
)
