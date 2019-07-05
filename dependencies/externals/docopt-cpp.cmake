SubdirectoryGuard(Docopt)
include(ExternalProj)

if(WIN32)
    set(DOCOPT_FLAGS "/EHsc")
endif()

AddExternalProject(docopt_proj
    GIT_REPOSITORY https://github.com/docopt/docopt.cpp.git
    GIT_TAG v0.6.2
    CMAKE_ARGS "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} ${DOCOPT_FLAGS}"
    STATIC_LIBRARIES docopt
)
