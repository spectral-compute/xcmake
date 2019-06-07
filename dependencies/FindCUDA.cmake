SubdirectoryGuard(FindCuda)

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
    SET (CUDA_TOOLKIT_ROOT $ENV{CUDA_TOOLKIT_ROOT})
else()
    SET(CUDA_TOOLKIT_ROOT "${CUDA_TOOLKIT_ROOT_DIR}")
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
    endif (ANDROID_ARCH_NAME STREQUAL "arm64")
else()
    # This usually works... :D
    set(CUDA_TOOLKIT_TARGET_NAME ${CMAKE_SYSTEM_PROCESSOR}-${CMAKE_SYSTEM_NAME})
    string(TOLOWER "${CUDA_TOOLKIT_TARGET_NAME}" CUDA_TOOLKIT_TARGET_NAME)
endif()

if(EXISTS "${CUDA_TOOLKIT_ROOT}/targets/${CUDA_TOOLKIT_TARGET_NAME}")
    set(CUDA_TOOLKIT_TARGET_DIR "${CUDA_TOOLKIT_ROOT}/targets/${CUDA_TOOLKIT_TARGET_NAME}" CACHE PATH "CUDA Toolkit target location.")
    SET (CUDA_TOOLKIT_ROOT_DIR ${CUDA_TOOLKIT_ROOT})
    mark_as_advanced(CUDA_TOOLKIT_TARGET_DIR)
else()
    SET(CUDA_TOOLKIT_TARGET_DIR ${CUDA_TOOLKIT_ROOT_DIR})
endif()

# add known CUDA targetr root path to the set of directories we search for programs, libraries and headers
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

function (locate_cuda_library _outvar _name _path_ext)
    if (CMAKE_SIZEOF_VOID_P EQUAL 8)
        # CUDA 3.2+ on Windows moved the library directories, so we need the new
        # and old paths.
        set(_cuda_64bit_lib_dir "${_path_ext}lib/x64" "${_path_ext}lib64" "${_path_ext}libx64" )
    endif()

    # CUDA 3.2+ on Windows moved the library directories, so we need to new
    # (lib/Win32) and the old path (lib).
    find_library(${_outvar}
        NAMES ${_name}
        PATHS
            "${CUDA_TOOLKIT_TARGET_DIR}"
            ENV CUDA_PATH
            ENV CUDA_LIB_PATH
            ENV NVTOOLSEXT_PATH
        PATH_SUFFIXES
            ${_cuda_64bit_lib_dir}
            "${_path_ext}lib/Win32"
            "${_path_ext}lib"
            "${_path_ext}libWin32"
            "${_path_ext}lib/x64"
        NO_DEFAULT_PATH
    )

    if(NOT CMAKE_CROSSCOMPILING)
        # Search default search paths, after we search our own set of paths.
        find_library(${_outvar}
            NAMES ${_name}
            PATHS "/usr/lib/nvidia-current"
        )
    endif()
endfunction()

function(create_cuda_library LIB_NAME IMP_PATH LIB_TYPE)
    add_library(${LIB_NAME} ${LIB_TYPE} IMPORTED GLOBAL)
    set_target_properties(${LIB_NAME} PROPERTIES
            IMPORTED_LOCATION "${IMP_PATH}"
    )
    if(${LIB_TYPE} STREQUAL SHARED)
        install(TARGETS ${LIB_NAME})
    endif()
    target_include_directories(${LIB_NAME} INTERFACE "${CUDA_TOOLKIT_INCLUDE}")
endfunction()

function(cuda_find_library _NAME)
    # Try to find the dynamic library.
    set(DYLIB_NAME ${CMAKE_SHARED_LIBRARY_PREFIX}${_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX})
    set(SLIB_NAME ${CMAKE_STATIC_LIBRARY_PREFIX}${_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX})

    string(TOUPPER ${_NAME} UNAME)
    set(DYLIB_VAR ${UNAME}_SHARED_PATH)
    set(SLIB_VAR ${UNAME}_STATIC_PATH)

    locate_cuda_library(${DYLIB_VAR} ${DYLIB_NAME} "")
    locate_cuda_library(${SLIB_VAR} ${SLIB_NAME} "")

    # Create library targets for paths we found
    if (${DYLIB_VAR})
        create_cuda_library(${_NAME} ${${DYLIB_VAR}} SHARED)
    endif()

    # Names static as dynamic would have been if dynamic wasn't found.
    # Please for the love of god let us alias IMPORTED targets...
    if(${SLIB_VAR})
        if(NOT TARGET ${_NAME})
            create_cuda_library(${_NAME} ${${SLIB_VAR}} STATIC)
        else()
            create_cuda_library(${_NAME}_static ${${SLIB_VAR}} STATIC)
        endif()
    endif()

    if(NOT TARGET ${_NAME} AND NOT TARGET ${_NAME}_static)
        message(FATAL_ERROR "Failed to find ${_NAME}")
    endif()
endfunction()

cuda_find_library(cudart)

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
cuda_find_library(nvToolsExt)
if (WIN32)
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
