include(FindPackageHandleStandardArgs)

file(GLOB INTEL_PATH RELATIVE /opt/ CONFIGURE_DEPENDS "/opt/intel/compilers_and_libraries*")

find_path(
    IPP_INCLUDE_DIR ipp.h
    PATHS /opt
    PATH_SUFFIXES ${INTEL_PATH}/linux/ipp/include
)

macro(find_ipp_lib SILLY_NAME PRETTY_NAME)
    if (TARGET IPP::${PRETTY_NAME})
        set(IPP_${PRETTY_NAME}_FOUND ON)
    else ()
        find_library(
            IPP_${PRETTY_NAME} ipp${SILLY_NAME}
            PATHS /opt
            PATH_SUFFIXES ${INTEL_PATH}/linux/ipp/lib/intel64_lin
        )

        if (IPP_${PRETTY_NAME})
            add_library(IPP::${PRETTY_NAME} SHARED IMPORTED GLOBAL)

            set_target_properties(IPP::${PRETTY_NAME} PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${IPP_INCLUDE_DIR}"
                IMPORTED_LOCATION "${IPP_${PRETTY_NAME}}"
            )

            set(IPP_${PRETTY_NAME}_FOUND ON)
        endif()
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
