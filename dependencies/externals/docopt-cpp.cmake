include_guard(GLOBAL)
include(ExternalProj)

set(DOCOPT_FLAGS "")
if(MSVC)
    set(DOCOPT_FLAGS "/EHsc") # Sets the exception handling mode
endif()

add_external_project(docopt_proj
    GIT_REPOSITORY https://github.com/docopt/docopt.cpp.git
    GIT_TAG 72a8e3e01effe22ac0f4e29c14153743172efcb5
    CMAKE_ARGS
        "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} ${DOCOPT_FLAGS}"
        "-DCMAKE_BUILD_TYPE=Release"
    SHARED_LIBRARIES docopt
)

if(XCMAKE_IMPLIB_PLATFORM)
    set(LIBNAME ${CMAKE_SHARED_LIBRARY_PREFIX}docopt${CMAKE_SHARED_LIBRARY_SUFFIX})
    externalproject_add_step(docopt_proj postinstall
        COMMAND ${CMAKE_COMMAND} -E rename ${CMAKE_BINARY_DIR}/external_projects/inst/lib/${LIBNAME} ${CMAKE_BINARY_DIR}/external_projects/inst/bin/${LIBNAME}
        COMMENT "Completed move of docopt.dll from lib to bin"
        DEPENDEES install
    )
endif()
