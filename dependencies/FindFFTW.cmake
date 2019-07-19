find_path(fftw_INCLUDE_DIRS fftw3.h)
find_library(fftw_LIBRARY_d fftw3)
find_library(fftw_LIBRARY_f fftw3f)

set(fftw_LIBRARIES ${fftw_LIBRARY_d} ${fftw_LIBRARY_f})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(FFTW DEFAULT_MSG fftw_INCLUDE_DIRS fftw_LIBRARIES)

if (fftw_FOUND)
    message("Found FFTW:\n     Includes: ${fftw_INCLUDE_DIRS}\n     Libraries: ${fftw_LIBRARIES}")
endif()
