find_path(PCRE_INCLUDE_DIRS pcre2.h)
find_library(PCRE_LIBRARIES pcre2-8)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PRCE DEFAULT_MSG PCRE_INCLUDE_DIRS PCRE_LIBRARIES)

if (PRCE_FOUND)
    message("Found PCRE:\n     Includes: ${PCRE_INCLUDE_DIRS}\n     Libraries: ${PCRE_LIBRARIES}")
endif()
