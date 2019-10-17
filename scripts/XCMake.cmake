# Include the TC _yet again_, because cmake drops some definitions during project() on some platforms,
# making some things undefined that should be empty-string...
include("${CMAKE_TOOLCHAIN_FILE}")

## Include the rest of xcmake, for convenience.
include(GTest)
include(Properties)
include(Documentation)

# Compute the project GUID as a hash of name and build type. We cheatily just truncate the hash and insert hypens to
# format it as a GUID that's consumed by various tools.
string(SHA512 XCMAKE_PROJECT_HASH "${CMAKE_PROJECT_NAME}${CMAKE_BUILD_TYPE}")
string(TOUPPER "${XCMAKE_PROJECT_HASH}" XCMAKE_PROJECT_HASH)
default_cache_value(XCMAKE_PROJECT_HASH ${XCMAKE_PROJECT_HASH})

# Reformat the hash as `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`. Can't use REGEX_REPLACE because it doesn't do variable
# quantifiers :(
function (set_project_guid)
    string(SUBSTRING ${XCMAKE_PROJECT_HASH} 0 8 GUID_0)
    string(SUBSTRING ${XCMAKE_PROJECT_HASH} 8 4 GUID_1)
    string(SUBSTRING ${XCMAKE_PROJECT_HASH} 12 4 GUID_2)
    string(SUBSTRING ${XCMAKE_PROJECT_HASH} 16 4 GUID_3)
    string(SUBSTRING ${XCMAKE_PROJECT_HASH} 20 12 GUID_4)
    default_cache_value(XCMAKE_PROJECT_GUID "${GUID_0}-${GUID_1}-${GUID_2}-${GUID_3}-${GUID_4}")
endfunction()

set_project_guid()

if (XCMAKE_PACKAGING)
    include(Packaging)
endif()
