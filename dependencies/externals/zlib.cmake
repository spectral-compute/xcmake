include_guard(GLOBAL)
include(ExternalProj)

# On Windows, we need _CRT_DECLARE_NONSTDC_NAMES.
set(LIB_NAME z)
if (WIN32)
    set(LIB_NAME zlibstatic)
    set(COMPILE_OPTIONS -D_CRT_DECLARE_NONSTDC_NAMES)
endif()

add_external_project(zlib_proj
    GIT_REPOSITORY    https://github.com/madler/zlib.git
    GIT_TAG           v1.2.12
    CMAKE_ARGS
        -DBUILD_SHARED_LIBS=OFF
    C_FLAGS "${COMPILE_OPTIONS} -Wno-deprecated-non-prototype"
    STATIC_LIBRARIES
        ${LIB_NAME}
)

if (WIN32)
    add_library(z ALIAS ${LIB_NAME})
endif()
