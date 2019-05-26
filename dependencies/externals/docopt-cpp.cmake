SubdirectoryGuard(Docopt)
include(ExternalProj)

AddExternalProject(docopt_proj
    GIT_REPOSITORY https://github.com/docopt/docopt.cpp.git
    GIT_TAG v0.6.2
    CMAKE_ARGS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    INSTALL_COMMAND make install && cp -RfT <INSTALL_DIR>/lib64 <INSTALL_DIR>/lib/ || true
    STATIC_LIBRARIES docopt
)
