include_guard(GLOBAL)
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
