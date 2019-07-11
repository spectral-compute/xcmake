SubdirectoryGuard(Docopt)
include(ExternalProj)

set(DOCOPT_FLAGS "")
set(DOCOPT_STATIC_NAME "docopt")
if(MSVC)
    set(DOCOPT_FLAGS "/EHsc") # Sets the exception handling mode
    set(DOCOPT_STATIC_NAME "docopt_s") # They manually set both names to "docopt" for nonwindows... Sigh.
endif()

AddExternalProject(docopt_proj
    GIT_REPOSITORY https://github.com/docopt/docopt.cpp.git
    GIT_TAG v0.6.2
    CMAKE_ARGS "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} ${DOCOPT_FLAGS}"
    # docopt always builds both libraries, but their names differ by platform
    STATIC_LIBRARIES ${DOCOPT_STATIC_NAME}
    SHARED_LIBRARIES docopt
)
ExternalProject_Add_Step(docopt_proj RUNCOMMAND
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/external_projects/inst/lib/docopt.dll ${CMAKE_BINARY_DIR}/external_projects/inst/bin
    COMMENT "Completed copy of docopt.dll from lib to bin"
    DEPENDEES install
)
