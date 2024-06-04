include_guard(GLOBAL)
include(ExternalProj)

get_ep_url(YAML_CPP_URL git@github.com:jbeder/yaml-cpp.git yaml-cpp)
add_external_project(yaml-cpp-proj
    GIT_REPOSITORY    ${YAML_CPP_URL}
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
