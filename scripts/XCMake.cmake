# Include the TC _yet again_, because cmake drops some definitions during project() on some platforms,
# making some things undefined that should be empty-string...
include("${CMAKE_TOOLCHAIN_FILE}")

## Include the rest of xcmake, for convenience.
include(Doxygen)
include(Properties)
include(Documentation)

# XCmake-specific build options
option(XCMAKE_PACKAGING "Enable installer generation. Disables lots of other things." OFF)
option(XCMAKE_SANITISE_TRADEMARKS "A list of trademarks to scan headers/documentation for. The last symbol of the word shall be the appropriate special symbol. Formatted as a list of <word>:<I<owner> pairs" "" STRING)
option(XCMAKE_ENABLE_TESTS "Build unit tests for all projects" ON)
option(XCMAKE_USE_NVCC "Use NVIDIA's compiler for CUDA translation units" OFF)
option(XCMAKE_ENABLE_DOCS "Generate documentation for all projects" ON)
option(XCMAKE_PRIVATE_DOCS "Build 'private' documentation" ON)
option(XCMAKE_PROJECTS_ARE_COMPONENTS "Assume a 1-1 mapping between projects and components. This simplifies some issues surrounding exports and installer generation." ON)
option(XCMAKE_PRINT_SUMMARY "Print the colour-ascii-art build summary after configuration" ON)

if (XCMAKE_PACKAGING)
    set(DEFAULT_INSTALL_DLLS OFF)
else()
    set(DEFAULT_INSTALL_DLLS ON)
endif()
option(XCMAKE_INSTALL_DEPENDENT_DLLS "Install copies of all the dlls that your installed targets depend on, if this is an IMPLIB project" ${DEFAULT_INSTALL_DLLS})
option(XCMAKE_PROJECT_INSTALL_PREFIX "Install everything to `${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/...`. This adds a per-project suffix to the install prefix." ${XCMAKE_PACKAGING})

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
    set(COMPONENT_INSTALL_ROOT "${PROJECT_NAME}/")

    if (XCMAKE_PRIVATE_DOCS)
        message(RED "Disabling XCMAKE_PRIVATE_DOCS because packaging is enabled")
        set(XCMAKE_PRIVATE_DOCS OFF CACHE INTERNAL "")
    endif()
    if (XCMAKE_ENABLE_TESTS)
        message(RED "Disabling XCMAKE_ENABLE_TESTS because packaging is enabled")
        set(XCMAKE_ENABLE_TESTS OFF CACHE INTERNAL "")
    endif()

    if (NOT XCMAKE_SANITISE_TRADEMARKS)
        message(BOLD_YELLOW "Warning: Packaging is enabled, but trademark sanitisation is not.")
    endif()
    if (NOT XCMAKE_ENABLE_DOCS)
        message(BOLD_YELLOW "Warning: Packaging is enabled, but documentation generation is not. The produced package will have no documentation!")
    endif()

    message(BOLD_RED "-----------------------------------------------------------------")
    message(BOLD_RED "- PACKAGING MODE IS ENABLED. THIS WILL DISABLE MOST COMPILATION -")
    message(BOLD_RED "-           Use -DXCMAKE_PACKAGING=OFF to disable               -")
    message(BOLD_RED "-----------------------------------------------------------------")

    include(Packaging)
else()
    set(COMPONENT_INSTALL_ROOT)
endif()
