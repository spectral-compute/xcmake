include(FindPackageHandleStandardArgs)

# Intel seems to enjoy hide-and-seek. To be maximally helpful, we'll provide platform-specific defaults that map to
# the default install locations. Users can explicitly set `IPP_ROOT` if they have it installed somewhere else...
if (WIN32)
    default_cache_value(IPP_ROOT "C:/Program Files (x86)/IntelSWTools" CACHE STRING "Directory containing the compilers_and_libraries* directory for IPP")
    set(IPP_PLATFORM "windows")
else()
    default_cache_value(IPP_ROOT "/opt/intel/" CACHE STRING "Directory containing the compilers_and_libraries* directory for IPP")
    set(IPP_PLATFORM "linux")
endif()

# Consistency is overrated.
string(SUBSTRING ${IPP_PLATFORM} 0 3 IPP_PLATFORM_SHORT)

# Dig into the version-specific one, naively.
file(GLOB INTEL_PATH CONFIGURE_DEPENDS "${IPP_ROOT}/compilers_and_libraries*")
if ("${INTEL_PATH}" STREQUAL "")
    message(FATAL_ERROR "Intel IPP installation not found in \"${IPP_ROOT}\". Maybe you need to set `IPP_ROOT`?")
endif()

list(GET INTEL_PATH 0 INTEL_PATH)
set(IPP_PATH "${INTEL_PATH}/${IPP_PLATFORM}/ipp")

find_path(
    IPP_INCLUDE_DIR ipp.h
    PATHS "${IPP_PATH}/include"
)

# The libraries are stored as follows:
# - Static libraries and implibs in `${IPP_PATH}/lib`.
# - Implibs named `ipp<X>.lib`, static libraries named `ipp<X>mt.lib` on Windows, `ipp<X>.a` on Linux/Mac.
# - DLLs in `${IPP_PATH}/../redist/<arch>/ipp/ipp<X>.dll`.
set(STATIC_LIBRARY_NAME_SUFFIX "")
set(SHARED_LIBRARY_PATH "lib/intel64_${IPP_PLATFORM_SHORT}")
if (WIN32)
    set(STATIC_LIBRARY_NAME_SUFFIX "mt")
    set(SHARED_LIBRARY_PATH "../redist/intel64_${IPP_PLATFORM_SHORT}/ipp")
endif()

#
# The "Silly name" below is the 1-or-2 letter codes Intel use to name their libraries, because apparently naming
# something `ippchmt.lib` makes it entirely clear that this is the single-threaded, statically-linked, string processing
# library.
macro(find_ipp_lib SILLY_NAME PRETTY_NAME)
    if (TARGET IPP::${PRETTY_NAME})
        set(IPP_${PRETTY_NAME}_FOUND ON)
    else ()
        set(STATIC_LIB_NAME ${CMAKE_STATIC_LIBRARY_PREFIX}ipp${SILLY_NAME}${STATIC_LIBRARY_NAME_SUFFIX}${CMAKE_STATIC_LIBRARY_SUFFIX})
        set(IMPLIB_NAME ${CMAKE_STATIC_LIBRARY_PREFIX}ipp${SILLY_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX})
        set(SHARED_LIB_NAME ${CMAKE_SHARED_LIBRARY_PREFIX}ipp${SILLY_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX})

        find_file(IPP_${PRETTY_NAME}_STATIC
            ${STATIC_LIB_NAME}
            PATHS "${IPP_PATH}/lib/intel64_${IPP_PLATFORM_SHORT}"
        )

        find_file(IPP_${PRETTY_NAME}_IMPLIB
            ${IMPLIB_NAME}
            PATHS "${IPP_PATH}/lib/intel64_${IPP_PLATFORM_SHORT}"
        )

        find_file(IPP_${PRETTY_NAME}_SHARED
            ${SHARED_LIB_NAME}
            PATHS "${IPP_PATH}/${SHARED_LIBRARY_PATH}"
        )

        # Randomly, some are static-only. Gracefully handle this situation.
        if (NOT IPP_${PRETTY_NAME}_SHARED)
            set(IPP_${PRETTY_NAME}_SHARED "${IPP_${PRETTY_NAME}_STATIC}")
            add_library(IPP::${PRETTY_NAME} STATIC IMPORTED GLOBAL)
        else()
            add_library(IPP::${PRETTY_NAME} SHARED IMPORTED GLOBAL)
        endif()

        if (IPP_${PRETTY_NAME}_SHARED OR IPP_${PRETTY_NAME}_STATIC)
            set(IPP_${PRETTY_NAME}_FOUND ON)
        endif()

        add_library(IPP::${PRETTY_NAME}_static STATIC IMPORTED GLOBAL)

        set_target_properties(IPP::${PRETTY_NAME} PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${IPP_INCLUDE_DIR}"
            IMPORTED_LOCATION "${IPP_${PRETTY_NAME}_SHARED}"
            IMPORTED_IMPLIB "${IPP_${PRETTY_NAME}_IMPLIB}"
        )

        set_target_properties(IPP::${PRETTY_NAME}_static PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${IPP_INCLUDE_DIR}"
            IMPORTED_LOCATION "${IPP_${PRETTY_NAME}_STATIC}"
        )
    endif()
endmacro()

find_ipp_lib(core Core)
find_ipp_lib(ch String)
find_ipp_lib(cc ColCon)
find_ipp_lib(cp Crypto)
find_ipp_lib(cv Vision)
find_ipp_lib(dc Compression)
find_ipp_lib(i Image)
find_ipp_lib(s Signal)
find_ipp_lib(vm Vector)

find_package_handle_standard_args(IPP
    HANDLE_COMPONENTS
    REQUIRED_VARS IPP_INCLUDE_DIR
)

# Build the list of output libraries from the components list.
set(IPP_LIBRARIES "")
foreach(_C ${IPP_FIND_COMPONENTS})
    list(APPEND IPP_LIBRARIES IPP::${_C})
endforeach()
