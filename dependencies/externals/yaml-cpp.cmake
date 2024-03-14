# git@github.com:jbeder/yaml-cpp.git

include(ExternalProj)
add_external_project(yaml-cpp-proj
    GIT_REPOSITORY    git@github.com:jbeder/yaml-cpp.git
    GIT_TAG           "0.8.0"
    CMAKE_ARGS
        -DYAML_CPP_BUILD_CONTRIB=OFF
        -DYAML_CPP_BUILD_TOOLS=OFF
        -DYAML_CPP_INSTALL=ON
        -DYAML_CPP_FORMAT_SOURCE=OFF
        -DYAML_CPP_DISABLE_UNINSTALL=OFF # WTF :D
        -DBUILD_TESTING=OFF
        -DCMAKE_CXX_FLAGS="-Wno-shadow"
        -DCMAKE_C_FLAGS="-Wno-shadow"

    LIBRARIES         yaml-cpp
)
