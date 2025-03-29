include_guard(GLOBAL)
include(ExternalProj)

option(XCMAKE_SYSTEM_DOCOPT "Use system docopt.cpp rather than build our own" Off)

if (XCMAKE_SYSTEM_DOCOPT)
    find_package(docopt REQUIRED)
else()
    include(ExternalProj)

    set(DOCOPT_FLAGS "")
    if(MSVC)
        set(DOCOPT_FLAGS "/EHsc") # Sets the exception handling mode
    endif()

    get_ep_url(DOCOPT_URL https://github.com/docopt/docopt.cpp.git docopt)
    add_external_project(docopt_proj
        GIT_REPOSITORY ${DOCOPT_URL}
        GIT_TAG 400e6dd8e59196c914dcc2c56caf7dae7efa5eb3
        CMAKE_ARGS -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DBUILD_SHARED_LIBS=Off
        CXX_FLAGS "${DOCOPT_FLAGS}"
        STATIC_LIBRARIES docopt
    )
endif()
