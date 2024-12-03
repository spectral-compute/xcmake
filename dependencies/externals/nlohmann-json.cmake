include_guard(GLOBAL)
include(ExternalProj)

get_ep_url(JSON_URL https://github.com/nlohmann/json.git nlohmann-json)
add_external_project(nlohmann-json-proj
    GIT_REPOSITORY    ${JSON_URL}
    GIT_TAG           "v3.11.3"
    CMAKE_ARGS
        -DJSON_BuildTests=OFF

    HEADER_LIBRARIES  nlohmann-json
)
