include(FindPackageHandleStandardArgs)

find_path(RE2_INCLUDE_DIR re2/re2.h)
find_library(RE2_LIBRARY re2)

find_package_handle_standard_args(RE2 REQUIRED_VARS RE2_LIBRARY RE2_INCLUDE_DIR)

if (NOT TARGET RE2)
    add_library(RE2 SHARED IMPORTED GLOBAL)
    set_target_properties(RE2 PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${RE2_INCLUDE_DIR}"
        IMPORTED_LOCATION "${RE2_LIBRARY}"
    )
endif()
