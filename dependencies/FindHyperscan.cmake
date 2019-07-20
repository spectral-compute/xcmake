include(FindPackageHandleStandardArgs)

find_path(Hyperscan_INCLUDE_DIR hs/hs.h)
find_library(Hyperscan_LIBRARY hs)

find_package_handle_standard_args(Hyperscan REQUIRED_VARS Hyperscan_LIBRARY Hyperscan_INCLUDE_DIR)

if (NOT TARGET Hyperscan)
    if(WIN32)
        add_library(Hyperscan STATIC IMPORTED GLOBAL)
    else()
        add_library(Hyperscan SHARED IMPORTED GLOBAL)
    endif()
    set_target_properties(Hyperscan PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${Hyperscan_INCLUDE_DIR}"
        IMPORTED_LOCATION "${Hyperscan_LIBRARY}"
    )
endif()
