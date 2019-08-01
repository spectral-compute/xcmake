include_guard(GLOBAL)

# Search for the cuda distribution.
if(NOT CUDA_TOOLKIT_ROOT_DIR AND NOT CMAKE_CROSSCOMPILING)
    # Search in the CUDA_BIN_PATH first.
    find_path(CUDA_TOOLKIT_ROOT_DIR
        NAMES nvcc nvcc.exe
        PATHS
            ENV CUDA_TOOLKIT_ROOT
            ENV CUDA_PATH
            ENV CUDA_BIN_PATH
        PATH_SUFFIXES bin bin64
        DOC "Toolkit location."
        NO_DEFAULT_PATH
        )

    # Now search default paths
    find_path(CUDA_TOOLKIT_ROOT_DIR
        NAMES nvcc nvcc.exe
        PATHS /opt/cuda/bin
        PATH_SUFFIXES cuda/bin
        DOC "Toolkit location."
        )

    if (CUDA_TOOLKIT_ROOT_DIR)
        string(REGEX REPLACE "[/\\\\]?bin[64]*[/\\\\]?$" "" CUDA_TOOLKIT_ROOT_DIR ${CUDA_TOOLKIT_ROOT_DIR})
        # We need to force this back into the cache.
        set(CUDA_TOOLKIT_ROOT_DIR ${CUDA_TOOLKIT_ROOT_DIR} CACHE PATH "Toolkit location." FORCE)
        set(CUDA_TOOLKIT_TARGET_DIR ${CUDA_TOOLKIT_ROOT_DIR})
    endif()

    if(NOT EXISTS ${CUDA_TOOLKIT_ROOT_DIR})
        if(CUDA_FIND_REQUIRED)
            message(FATAL_ERROR "Specify CUDA_TOOLKIT_ROOT_DIR")
        elseif(NOT CUDA_FIND_QUIETLY)
            message("CUDA_TOOLKIT_ROOT_DIR not found or specified")
        endif()
    endif()
endif()

if(CMAKE_CROSSCOMPILING)
    set (CUDA_TOOLKIT_ROOT $ENV{CUDA_TOOLKIT_ROOT})
else()
    set (CUDA_TOOLKIT_ROOT "${CUDA_TOOLKIT_ROOT_DIR}")
endif()

if(CMAKE_SYSTEM_PROCESSOR STREQUAL "armv7-a")
    # Support for NVPACK
    set (CUDA_TOOLKIT_TARGET_NAME "armv7-linux-androideabi")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
    # Support for arm cross compilation
    set(CUDA_TOOLKIT_TARGET_NAME "armv7-linux-gnueabihf")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    # Support for aarch64 cross compilation
    if (ANDROID_ARCH_NAME STREQUAL "arm64")
        set(CUDA_TOOLKIT_TARGET_NAME "aarch64-linux-androideabi")
    else()
        set(CUDA_TOOLKIT_TARGET_NAME "aarch64-linux")
    endif ()
else()
    # This usually works... :D
    set(CUDA_TOOLKIT_TARGET_NAME ${CMAKE_SYSTEM_PROCESSOR}-${CMAKE_SYSTEM_NAME})
    string(TOLOWER "${CUDA_TOOLKIT_TARGET_NAME}" CUDA_TOOLKIT_TARGET_NAME)
endif()

if(EXISTS "${CUDA_TOOLKIT_ROOT}/targets/${CUDA_TOOLKIT_TARGET_NAME}")
    set(CUDA_TOOLKIT_TARGET_DIR "${CUDA_TOOLKIT_ROOT}/targets/${CUDA_TOOLKIT_TARGET_NAME}" CACHE PATH "CUDA Toolkit target location.")
    set(CUDA_TOOLKIT_ROOT_DIR ${CUDA_TOOLKIT_ROOT})
    mark_as_advanced(CUDA_TOOLKIT_TARGET_DIR)
else()
    set(CUDA_TOOLKIT_TARGET_DIR ${CUDA_TOOLKIT_ROOT_DIR})
endif()

# Add known CUDA target root path to the set of directories we search for programs, libraries and headers
set(CMAKE_FIND_ROOT_PATH "${CUDA_TOOLKIT_TARGET_DIR};${CMAKE_FIND_ROOT_PATH}")

# CUDA_NVCC_EXECUTABLE
if(DEFINED ENV{CUDA_NVCC_EXECUTABLE})
    set(CUDA_NVCC_EXECUTABLE "$ENV{CUDA_NVCC_EXECUTABLE}" CACHE FILEPATH "NVIDIA's CUDA compiler")
else()
    find_program(CUDA_NVCC_EXECUTABLE
        NAMES nvcc
        PATHS "${CUDA_TOOLKIT_ROOT_DIR}"
        ENV CUDA_PATH
        ENV CUDA_BIN_PATH
        PATH_SUFFIXES bin bin64
        NO_DEFAULT_PATH
        )
    # Search default search paths, after we search our own set of paths.
    find_program(CUDA_NVCC_EXECUTABLE nvcc)
endif()
mark_as_advanced(CUDA_NVCC_EXECUTABLE)

if(CUDA_NVCC_EXECUTABLE AND NOT CUDA_VERSION)
    # Compute the version.
    execute_process (COMMAND ${CUDA_NVCC_EXECUTABLE} "--version" OUTPUT_VARIABLE NVCC_OUT)
    string(REGEX REPLACE ".*release ([0-9]+)\\.([0-9]+).*" "\\1" CUDA_VERSION_MAJOR ${NVCC_OUT})
    string(REGEX REPLACE ".*release ([0-9]+)\\.([0-9]+).*" "\\2" CUDA_VERSION_MINOR ${NVCC_OUT})
    set(CUDA_VERSION "${CUDA_VERSION_MAJOR}.${CUDA_VERSION_MINOR}" CACHE STRING "Version of CUDA as computed from nvcc.")
    mark_as_advanced(CUDA_VERSION)
else()
    # Need to set these based off of the cached value
    string(REGEX REPLACE "([0-9]+)\\.([0-9]+).*" "\\1" CUDA_VERSION_MAJOR "${CUDA_VERSION}")
    string(REGEX REPLACE "([0-9]+)\\.([0-9]+).*" "\\2" CUDA_VERSION_MINOR "${CUDA_VERSION}")
endif()

# Always set this convenience variable
set(CUDA_VERSION_STRING "${CUDA_VERSION}")

# CUDA_TOOLKIT_INCLUDE
find_path(CUDA_TOOLKIT_INCLUDE
    device_functions.h # Header included in toolkit
    PATHS ${CUDA_TOOLKIT_TARGET_DIR}
    ENV CUDA_PATH
    ENV CUDA_INC_PATH
    PATH_SUFFIXES include
    NO_DEFAULT_PATH
)
set(CUDA_INCLUDE_DIRS ${CUDA_TOOLKIT_INCLUDE} CACHE STRING "CUDA Include directories")
mark_as_advanced(CUDA_INCLUDE_DIRS)

# Search default search paths, after we search our own set of paths.
find_path(CUDA_TOOLKIT_INCLUDE device_functions.h)
mark_as_advanced(CUDA_TOOLKIT_INCLUDE)

if(CUDA_VERSION VERSION_GREATER "7.0" OR EXISTS "${CUDA_TOOLKIT_INCLUDE}/cuda_fp16.h")
    set(CUDA_HAS_FP16 TRUE)
else()
    set(CUDA_HAS_FP16 FALSE)
endif()

function (locate_cuda_library)
    set(oneValueArgs LIBPATH DLLPATH TYPE)
    set(multiValueArgs NAMES)
    cmake_parse_arguments("arg" "" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

    # Fully populate the names to search for
    set(FULL_NAMES "")
    foreach(NAME ${arg_NAMES})
        list(APPEND FULL_NAMES ${CMAKE_${arg_TYPE}_LIBRARY_PREFIX}${NAME}${CMAKE_${arg_TYPE}_LIBRARY_SUFFIX})
    endforeach()

    # CUDA 3.2+ on Windows moved the library directories, so we need to new
    # (lib/Win32) and the old path (lib).
    find_library(${arg_LIBPATH}
        NAMES ${arg_NAMES}
        PATHS
            "${CUDA_TOOLKIT_TARGET_DIR}"
            ENV CUDA_PATH
            ENV CUDA_LIB_PATH
            ENV NVTOOLSEXT_PATH
        PATH_SUFFIXES
            lib/x64
            lib64
            libx64
            lib/Win32
            lib
            libWin32
        NO_DEFAULT_PATH
    )

    if(arg_DLLPATH)
        find_file(${arg_DLLPATH}
            NAMES ${FULL_NAMES}
            PATHS
                "${CUDA_TOOLKIT_TARGET_DIR}"
                ENV CUDA_PATH
                ENV CUDA_LIB_PATH
                ENV NVTOOLSEXT_PATH
            PATH_SUFFIXES
                bin
                bin/x64
                bin/Win32
            NO_DEFAULT_PATH
        )
    endif()

    if(NOT CMAKE_CROSSCOMPILING)
        # Search default search paths, after we search our own set of paths.
        find_library(${arg_LIBPATH}
            NAMES ${FULL_NAMES}
            PATHS "/usr/lib/nvidia-current"
        )
        if(arg_DLLPATH)
            find_file(${arg_DLLPATH}
                NAMES ${FULL_NAMES}
                PATHS "/usr/lib/nvidia-current"
            )
        endif()
    endif()
endfunction()

function(create_cuda_library LIB_NAME LIB_TYPE IMPORT_PATH)
    cmake_parse_arguments("arg" "" "IMPLIB_PATH" "" "${ARGN}")

    add_library(${LIB_NAME} ${LIB_TYPE} IMPORTED GLOBAL)

    # This is the shared library on Linux and the DLL on Windows
    set_target_properties(${LIB_NAME} PROPERTIES IMPORTED_LOCATION "${IMPORT_PATH}")

    if(XCMAKE_IMPLIB_PLATFORM)
        # Strip filename from IMPORT PATH for storage as search path
        get_filename_component(DLL_PATH ${IMPORT_PATH} DIRECTORY)

        set_target_properties(${LIB_NAME} PROPERTIES
            IMPORTED_IMPLIB "${arg_IMPLIB_PATH}"
            INTERFACE_DLL_SEARCH_PATHS "${DLL_PATH}"
        )
    endif()

    target_include_directories(${LIB_NAME} INTERFACE "${CUDA_TOOLKIT_INCLUDE}")
endfunction()

function(cuda_find_library LIBNAME)
    set(flags FATAL)
    set(oneValueArgs STATICNAME) # For when the static and dynamic libs have fully different names
    set(multiValueArgs EXTRANAMES) # For when we have to go find weird names, such as on windows
    cmake_parse_arguments("arg" "${flags}" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}")

    # find_library creates a cache variable, so to make it unique append the library name to the start
    set(SHARED_PATH ${LIBNAME}_SHARED_PATH) # Shared lib on Linux. Implib on Windows.
    set(DLL_PATH ${LIBNAME}_DLL_PATH) # Will be empty on linux systems
    set(STATIC_PATH ${LIBNAME}_STATIC_PATH)

    # Look for stupid filenames on Windows according to CUDA version
    list(APPEND arg_EXTRANAMES "${LIBNAME}64_100" "${LIBNAME}64_101") # TODO: This needs to harvest 32/64 bit, and a condensed cuda version

    # Try to find the library locations
    # Filenames are located in the order they are presented to the NAMES argument
    # Put STATICNAME first so that, in the event of implib, it grabs the dedicated static library
    locate_cuda_library(LIBPATH ${SHARED_PATH} DLLPATH "${DLL_PATH}" NAMES ${LIBNAME} ${arg_EXTRANAMES} TYPE SHARED)
    locate_cuda_library(LIBPATH "${STATIC_PATH}" NAMES ${arg_STATICNAME} ${LIBNAME} ${arg_EXTRANAMES} TYPE STATIC)

    # Create library targets for paths we found
    if (${SHARED_PATH})
        if(XCMAKE_IMPLIB_PLATFORM AND ${DLL_PATH})
            create_cuda_library(${LIBNAME} SHARED ${${DLL_PATH}} IMPLIB_PATH ${${SHARED_PATH}})
        elseif(NOT XCMAKE_IMPLIB_PLATFORM)
            create_cuda_library(${LIBNAME} SHARED ${${SHARED_PATH}})
        endif()
    endif()

    # Names static as dynamic would have been if dynamic wasn't found.
    # Please for the love of god let us alias IMPORTED targets...
    if(${STATIC_PATH})
        if(NOT TARGET ${LIBNAME})
            create_cuda_library(${LIBNAME} STATIC ${${STATIC_PATH}})
        else()
            create_cuda_library(${LIBNAME}_static STATIC ${${STATIC_PATH}})
        endif()
    endif()

    if(NOT TARGET ${LIBNAME} AND NOT TARGET ${LIBNAME}_static)
        if(arg_FATAL)
            message(FATAL_ERROR "Failed to find ${LIBNAME}")
        else()
            message(WARNING "Failed to find ${LIBNAME}")
        endif()
    endif()
endfunction()

cuda_find_library(cudart STATICNAME cudart_static)

if(NOT CUDA_VERSION VERSION_LESS "5.0")
    cuda_find_library(cudadevrt)
endif()

# Special treatments for cudart when using the static version
if(TARGET cudart)
    get_target_property(CUDART_TYPE cudart TYPE)
    if(${CUDART_TYPE} STREQUAL STATIC_LIBRARY)
        if (UNIX)
            find_package(Threads REQUIRED)

            if(NOT APPLE)
                # On Linux, you must link against librt when using the static cuda runtime.
                find_library(CUDA_rt_LIBRARY rt)
                target_link_libraries(cudart INTERFACE ${CUDA_rt_LIBRARY})
                if (NOT CUDA_rt_LIBRARY)
                    message(WARNING "Expecting to find librt for libcudart_static, but didn't find it.")
                endif()
            endif()
        endif()

        target_link_libraries(cudart INTERFACE ${CMAKE_THREAD_LIBS_INIT} ${CMAKE_DL_LIBS})

        if(APPLE)
            # We need to add the default path to the driver (libcuda.dylib) as an rpath, so that
            # the static cuda runtime can find it at runtime.
            target_link_options(cudart INTERFACE -Wl,-rpath,/usr/local/cuda/lib)
        endif()
    endif()
endif()

# Search for additional CUDA toolkit libraries.
cuda_find_library(cufft)
cuda_find_library(cublas)
cuda_find_library(cusparse)
cuda_find_library(curand)

# The tools extension library is an optional package, so some users may be building software which doesn't require it
# Therefore, allow xcmake to silently fail-to-find when told it's allowed to (-DXCMAKE_NVTOOLSEXT_REQUIRED=FALSE)
default_value(XCMAKE_NVTOOLSEXT_REQUIRED TRUE)
cuda_find_library(nvToolsExt EXTRANAMES nvToolsExt64_1 FATAL ${XCMAKE_NVTOOLSEXT_REQUIRED})

# NVidia conveniently changed the location of the tool extension headers packaged with the rest of CUDA in 10.0
# Prior versions they are in the same place as the other headers, so get added in create_cuda_library
if(TARGET nvToolsExt AND (CUDA_VERSION STREQUAL "10.0" OR CUDA_VERSION VERSION_GREATER "10.0"))
    target_include_directories(nvToolsExt INTERFACE "${CUDA_TOOLKIT_INCLUDE}/nvtx3")
endif()

if(WIN32 AND XCMAKE_USE_CUDA_VIDEO)
    cuda_find_library(nvcuvenc)
    cuda_find_library(nvcuvid)
endif()

if(CUDA_VERSION VERSION_GREATER "5.0" AND CUDA_VERSION VERSION_LESS "9.2")
    # In CUDA 9.2 cublas_device was deprecated
    cuda_find_library(cublas_device)
endif()

if(NOT CUDA_VERSION VERSION_LESS "9.0")
    # In CUDA 9.0 NPP was nppi was removed
    cuda_find_library(nppc)
    cuda_find_library(nppial)
    cuda_find_library(nppicc)
    cuda_find_library(nppicom)
    cuda_find_library(nppidei)
    cuda_find_library(nppif)
    cuda_find_library(nppig)
    cuda_find_library(nppim)
    cuda_find_library(nppist)
    cuda_find_library(nppisu)
    cuda_find_library(nppitc)
    cuda_find_library(npps)
elseif(CUDA_VERSION VERSION_GREATER "5.0")
    # In CUDA 5.5 NPP was split into 3 separate libraries.
    cuda_find_library(nppc)
    cuda_find_library(nppi)
    cuda_find_library(npps)
elseif(NOT CUDA_VERSION VERSION_LESS "4.0")
    cuda_find_library(npp)
endif()

if(NOT CUDA_VERSION VERSION_LESS "7.0")
    # cusolver showed up in version 7.0
    cuda_find_library(cusolver)
endif()

#############################
# Check for required components
set(CUDA_FOUND TRUE)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(CUDA
    REQUIRED_VARS
        CUDA_TOOLKIT_ROOT_DIR
        CUDA_NVCC_EXECUTABLE
    VERSION_VAR
        CUDA_VERSION
)
