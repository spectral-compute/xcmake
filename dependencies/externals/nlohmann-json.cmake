include_guard(GLOBAL)
include(ExternalProj)

# The release tarball is tiny, while even a shallow clone fetches over a hundred megabytes.
get_ep_url(JSON_URL https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz nlohmann-json)
add_external_project(nlohmann-json-proj
    URL               ${JSON_URL}
    URL_HASH          SHA256=d6c65aca6b1ed68e7a182f4757257b107ae403032760ed6ef121c9d55e81757d
    CMAKE_ARGS
        -DJSON_BuildTests=OFF

    HEADER_LIBRARIES  nlohmann-json
)
