if (XCMAKE_INCLUDED)
    return()
endif ()
set(XCMAKE_INCLUDED ON)


# This script is included before project(), and can do initial envrionment configuration.
cmake_policy(VERSION 3.8.2)

set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../toolchain/toolchain.cmake)
include(${CMAKE_TOOLCHAIN_FILE})

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR} ${CMAKE_CURRENT_LIST_DIR}/../dependencies)

set(XCMAKE_SCRIPT_DIR ${CMAKE_CURRENT_LIST_DIR})
set(XCMAKE_TOOLS_DIR ${CMAKE_CURRENT_LIST_DIR}/../tools)

include(Utils)
include(Log)

# Default to building shared libraries
default_cache_value(BUILD_SHARED_LIBS ON)

# This gets annoying, since we recursively invoke cmake...
set(CMAKE_INSTALL_MESSAGE NEVER)

# We must always have a build type.
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug")
endif()

# Canonicalise build type
string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE)
if ("${CMAKE_BUILD_TYPE}" STREQUAL "DEBUG")
    set(CMAKE_BUILD_TYPE "Debug" CACHE INTERNAL "")
    add_definitions(-DDEBUG)
elseif("${CMAKE_BUILD_TYPE}" STREQUAL "RELEASE")
    set(CMAKE_BUILD_TYPE "Release" CACHE INTERNAL "")
    add_definitions(-DRELEASE)
elseif("${CMAKE_BUILD_TYPE}" STREQUAL "RELWITHDEBINFO")
    set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE INTERNAL "")
    add_definitions(-DDEBUG)
    add_definitions(-DRELEASE)
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
include(Properties)
include(Targets)
include(Headers)
include(CUDA)
include(GTest)
include(Export)
