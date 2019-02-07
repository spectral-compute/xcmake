if (XCMAKE_INCLUDED)
    return()
endif ()
set(XCMAKE_INCLUDED ON)


# This script is included before project(), and can do initial envrionment configuration.
cmake_policy(VERSION 3.12)
if (POLICY CMP0077)
    cmake_policy(SET CMP0077 NEW)
endif ()

set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../toolchain/toolchain.cmake)
include(${CMAKE_TOOLCHAIN_FILE})

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR} ${CMAKE_CURRENT_LIST_DIR}/../dependencies)

set(XCMAKE_SCRIPT_DIR ${CMAKE_CURRENT_LIST_DIR})
set(XCMAKE_TOOLS_DIR ${CMAKE_CURRENT_LIST_DIR}/../tools)

include(Utils) # Utility functions for list manipulation and so on.
include(Log)   # Logging utils.

# Default to building shared libraries
default_cache_value(BUILD_SHARED_LIBS ON)

# Remind cmake to stop drinking drain cleaner.
default_cache_value(CMAKE_INSTALL_MESSAGE NEVER) # No logspam during install
default_cache_value(CMAKE_INCLUDE_DIRECTORIES_BEFORE ON) # Prepend include directories by default.
default_cache_value(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION ON) # Absolute install paths are always wrong.
default_cache_value(CMAKE_ERROR_DEPRECATED ON) # Explode on use of deprecated cmake features

# Make sure externally fetched objects can be installed. Without this, ExternalData creates a relative symlink to a file
# in the build directory. When this is installed, the relative symlink is broken. If ExternalData_OBJECT_STORES is used
# to specify a directory outside the build directory, then this is not a problem and the symlink can be installed.
if (NOT ExternalData_OBJECT_STORES)
    set(ExternalData_NO_SYMLINKS On CACHE INTERNAL "")
endif()

# We must always have a build type.
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
endif()

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

# Saneify CMake's RPATH handling...
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# Include the rest of xcmake, for convenience.
include(ArgHandle)
include(ExternalProj)
include(Targets)
include(IncludeGuard)
include(Headers)
include(CUDA)
include(Test)
include(GTest)
include(Export)
include(ScopedSubdirs)
include(OnExit)
include(Summary)
include(Doxygen)

# All targets should, by default, have hidden visibility. This isn't in the toolchain because it's useful to be able to
# build others' libraries with that toolchain.
default_value(CMAKE_CXX_VISIBILITY_PRESET "hidden")
default_value(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

# A "make all the documentation" target. The scripts that make documentation targets attach their targets to this.
add_custom_target(docs ALL)

