include(FindPackageHandleStandardArgs)

find_path(PCRE2_INCLUDE_DIR pcre2.h)

foreach(_C 8 16 32)
    find_library(PCRE2_C${_C} pcre2-${_C})

    if (PCRE2_C${_C})
        add_library(PCRE2::C${_C} SHARED IMPORTED GLOBAL)

        set_target_properties(PCRE2::C${_C} PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${PCRE2_INCLUDE_DIR}"
            IMPORTED_LOCATION "${PCRE2_C${_C}}"
        )
        set(PCRE2_C${_C}_FOUND ON)
    endif()
endforeach()

find_package_handle_standard_args(PCRE2
    HANDLE_COMPONENTS
    REQUIRED_VARS PCRE2_INCLUDE_DIR
)
