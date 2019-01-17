find_path(IPP_INCLUDE_DIRS ipp.h
          PATHS /opt
          PATH_SUFFIXES intel/compilers_and_libraries_2018.3.222/linux/ipp/include)
find_library(IPP_LIBRARY_CORE ippcore
             PATHS /opt
             PATH_SUFFIXES intel/compilers_and_libraries_2018.3.222/linux/ipp/lib/intel64_lin)

find_library(IPP_LIBRARY_CH ippch
             PATHS /opt
             PATH_SUFFIXES intel/compilers_and_libraries_2018.3.222/linux/ipp/lib/intel64_lin)
find_library(IPP_LIBRARY_S ipps
             PATHS /opt
             PATH_SUFFIXES intel/compilers_and_libraries_2018.3.222/linux/ipp/lib/intel64_lin)
find_library(IPP_LIBRARY_VM ippvm
             PATHS /opt
             PATH_SUFFIXES intel/compilers_and_libraries_2018.3.222/linux/ipp/lib/intel64_lin)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(IPP DEFAULT_MSG
                                  IPP_INCLUDE_DIRS
                                  IPP_LIBRARY_CORE
                                  IPP_LIBRARY_CH
                                  IPP_LIBRARY_S
                                  IPP_LIBRARY_VM)

set(IPP_LIBRARIES ${IPP_LIBRARY_CORE} ${IPP_LIBRARY_VM} ${IPP_LIBRARY_S} ${IPP_LIBRARY_CH})

if (IPP_FOUND)
    message("Found IPP:\n     Includes: ${IPP_INCLUDE_DIRS}\n     Libraries: ${IPP_LIBRARIES}")
endif()
