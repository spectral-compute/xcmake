include(FindPackageHandleStandardArgs)

find_path(PCRE2_INCLUDE_DIR pcre2.h)

foreach(_C 8 16 32)
    find_library(PCRE2_C${_C} NAMES pcre2-${_C} pcre2-${_C}-static libpcre2-${_C}-static libpcre2-${_C})

    if (PCRE2_C${_C})
        if (NOT TARGET PCRE2::C${_C})
            if(WIN32)
                add_library(PCRE2::C${_C} STATIC IMPORTED GLOBAL)
                target_compile_definitions(PCRE2::C${_C} INTERFACE PCRE2_STATIC=1)
            else()
                add_library(PCRE2::C${_C} SHARED IMPORTED GLOBAL)
            endif()

            set_target_properties(PCRE2::C${_C} PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${PCRE2_INCLUDE_DIR}"
                IMPORTED_LOCATION "${PCRE2_C${_C}}"
            )
        endif()
        set(PCRE2_C${_C}_FOUND ON)
    endif()
endforeach()

find_package_handle_standard_args(PCRE2
    HANDLE_COMPONENTS
    REQUIRED_VARS PCRE2_INCLUDE_DIR
)
