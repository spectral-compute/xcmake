include_guard(GLOBAL)

option(XCMAKE_SYSTEM_DOCOPT "Use system docopt.cpp rather than build our own" Off)

if (XCMAKE_SYSTEM_DOCOPT)
    find_package(docopt REQUIRED)
else()
    include(ExternalProj)

    set(DOCOPT_FLAGS "")
    if(MSVC)
        set(DOCOPT_FLAGS "/EHsc") # Sets the exception handling mode
    endif()

    add_external_project(docopt_proj
        GIT_REPOSITORY https://github.com/docopt/docopt.cpp.git
        GIT_TAG 42ebcec9dc2c99a1b3a4542787572045763ad196
        CMAKE
        CXX_FLAGS "${DOCOPT_FLAGS}"
        STATIC_LIBRARIES docopt
    )
endif()
