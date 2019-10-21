if (XCMAKE_INCLUDED)
    return()
endif ()
set(XCMAKE_INCLUDED ON)


# This script is included before project(), and can do initial envrionment configuration.
cmake_policy(VERSION 3.13)

set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../toolchain/toolchain.cmake)

# We have one toolchain file to rule them all, so users are not expected to need to change it. Ever.
mark_as_advanced(CMAKE_TOOLCHAIN_FILE)
include(${CMAKE_TOOLCHAIN_FILE})

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR} ${CMAKE_CURRENT_LIST_DIR}/../dependencies)

set(XCMAKE_SCRIPT_DIR ${CMAKE_CURRENT_LIST_DIR})
set(XCMAKE_TOOLS_DIR ${CMAKE_CURRENT_LIST_DIR}/../tools)
set(XCMAKE_RESOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/../res)

include(Utils) # Utility functions for list manipulation and so on.
include(Log)   # Logging utils.

# Default to building shared libraries
default_cache_value(BUILD_SHARED_LIBS ON)

# Load the vendor configuration.
default_cache_value(XCMAKE_VENDOR_CONFIG "${XCMAKE_SCRIPT_DIR}/../VendorConfig.cmake")
include("${XCMAKE_VENDOR_CONFIG}")

# Default to a canonical output directory structure.
default_cache_value(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
default_cache_value(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
default_cache_value(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
default_cache_value(CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
default_cache_value(CMAKE_PDB_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

# Remind cmake to stop drinking drain cleaner.
default_cache_value(CMAKE_INSTALL_MESSAGE NEVER) # No logspam during install
default_cache_value(CMAKE_INCLUDE_DIRECTORIES_BEFORE ON) # Prepend include directories by default.
default_cache_value(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION ON) # Absolute install paths are always wrong.
default_cache_value(CMAKE_ERROR_DEPRECATED ON) # Explode on use of deprecated cmake features

# It makes zero sense to limit downloads to 10 minutes by default...
# This disables the total download time limit, but leaves the activity timeout unchanged.
default_cache_value(ExternalData_TIMEOUT_ABSOLUTE 0)

# Remind the user to stop drinking drain cleaner
if ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
    message(FATAL_ERROR "In-tree builds are not wise.")
endif()
if (NOT CMAKE_INSTALL_PREFIX)
    message(FATAL_ERROR "Please specify a value for `CMAKE_INSTALL_PREFIX`.")
endif()

# Make sure externally fetched objects can be installed. Without this, ExternalData creates a relative symlink to a file
# in the build directory. When this is installed, the relative symlink is broken. If ExternalData_OBJECT_STORES is used
# to specify a directory outside the build directory, then this is not a problem and the symlink can be installed.
if (NOT ExternalData_OBJECT_STORES)
    set(ExternalData_NO_SYMLINKS On CACHE INTERNAL "")
endif()

# We must always have a build type.
default_cache_value(CMAKE_BUILD_TYPE Debug)

# Sensible default for this on single-config generators.
default_cache_value(CMAKE_CONFIGURATION_TYPES ${CMAKE_BUILD_TYPE})

# Ensure build type is valid, and set it to the canonical value.
string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE)
if ("${CMAKE_BUILD_TYPE}" STREQUAL "DEBUG")
    set(CMAKE_BUILD_TYPE "Debug" CACHE INTERNAL "")
elseif("${CMAKE_BUILD_TYPE}" STREQUAL "RELEASE")
    set(CMAKE_BUILD_TYPE "Release" CACHE INTERNAL "")
elseif("${CMAKE_BUILD_TYPE}" STREQUAL "RELWITHDEBINFO")
    set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE INTERNAL "")
else()
    message(FATAL_ERROR "Unsupported build type: ${CMAKE_BUILD_TYPE}")
endif()

# Target properties to track DLL search paths.
define_property(TARGET PROPERTY DLL_SEARCH_PATHS
    BRIEF_DOCS "List of paths where dependent DLLs are found"
    FULL_DOCS "Set on executable targets and filled from INTERFACE_DLL_SEARCH_PATHS of linked libraries. \
    On platforms which use implibs for shared libraries, the library is not required for \
    linking, but is required for execution. This list can be used to populate build or install trees \
    with the necessary files (usually DLL)."
)
define_property(TARGET PROPERTY INTERFACE_DLL_SEARCH_PATHS
    BRIEF_DOCS "List of paths where dependent DLLs are found"
    FULL_DOCS "Set on library targets and propogates on INTERFACE or PUBLIC linking. On platforms \
    which use implibs for shared libraries, the library is not required for linking, but is required \
    for execution. This list can be used to populate build or install trees with the necessary files (usually DLL)."
)

# Saneify CMake's RPATH handling...
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# Include the rest of xcmake, for convenience.
include(ArgHandle)
include(CustomCommands)
include(Option)
include(SearchFunctions)
include(Targets)
include(IncludeGuard)
include(Headers)
include(Install)
include(CUDA)
include(Test)
include(Export)
include(ScopedSubdirs)
include(OnExit)
include(Summary)
include(Doxygen)
include(Pandoc)

# XCmake-specific build options
option(XCMAKE_PACKAGING "Enable installer generation. Disables lots of other things." OFF)
option(XCMAKE_SANITISE_TRADEMARKS "A list of trademarks to scan headers/documentation for. The last symbol of the word shall be the appropriate special symbol. Formatted as a list of <word>:<I<owner> pairs" "" STRING)
option(XCMAKE_ENABLE_TESTS "Build unit tests for all projects" ON)
option(XCMAKE_ENABLE_DOCS "Generate documentation for all projects" ON)
option(XCMAKE_PRIVATE_DOCS "Build 'private' documentation" ON)

if (XCMAKE_PACKAGING)
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
endif()

# All targets should, by default, have hidden visibility. This isn't in the toolchain because it's useful to be able to
# build others' libraries with that toolchain.
default_value(CMAKE_CXX_VISIBILITY_PRESET "hidden")
default_value(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

# A "make all the documentation" target. The scripts that make documentation targets attach their targets to this.
add_custom_target(docs ALL)

# Exclude effect targets from the output of cmake GraphViz graphs.
file(WRITE ${CMAKE_BINARY_DIR}/CMakeGraphVizOptions.cmake
    "set(GRAPHVIZ_IGNORE_TARGETS \".*_EFFECTS\")"
)
include(CMakeGraphVizOptions)
