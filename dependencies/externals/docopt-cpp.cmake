include_guard(GLOBAL)
include(ExternalProj)

set(DOCOPT_FLAGS "")
if (WIN32)
    set(DOCOPT_FLAGS "/EHsc")
endif()

AddExternalProject(docopt_proj
    GIT_REPOSITORY https://github.com/docopt/docopt.cpp.git
    GIT_TAG v0.6.2
    CMAKE_ARGS "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} ${DOCOPT_FLAGS}"
    STATIC_LIBRARIES docopt
)
ExternalProject_Add_Step(docopt_proj RUNCOMMAND
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/external_projects/inst/lib/docopt.dll ${CMAKE_BINARY_DIR}/external_projects/inst/bin
    COMMENT "Completed copy of docopt.dll from lib to bin"
    DEPENDEES install
)
