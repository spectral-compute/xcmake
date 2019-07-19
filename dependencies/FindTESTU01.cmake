include(FindPackageHandleStandardArgs)

find_path(
    TESTU01_INCLUDE_DIR
    NAMES TestU01.h
    PATH_SUFFIXES testu01
)

# Find the three libraries...
find_library(TESTU01_LIB NAMES testu01)
find_library(TESTU01_PROBDIST NAMES probdist)
find_library(TESTU01_MYLIB NAMES mylib)

mark_as_advanced(TESTU01_LIB TESTU01_PROBDIST TESTU01_MYLIB)

find_package_handle_standard_args(TESTU01
    REQUIRED_VARS TESTU01_INCLUDE_DIR TESTU01_MYLIB TESTU01_LIB TESTU01_PROBDIST
)

if (TestU01_FOUND AND NOT TARGET TestU01::TestU01)
    add_library(TestU01::TestU01 SHARED IMPORTED GLOBAL)
    add_library(TestU01::ProbDist SHARED IMPORTED GLOBAL)
    add_library(TestU01::MyLib SHARED IMPORTED GLOBAL)

    set_target_properties(TestU01::TestU01 PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${TESTU01_INCLUDE_DIR}"
        IMPORTED_LOCATION "${TESTU01_LIB}"
    )
    set_target_properties(TestU01::ProbDist PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${TESTU01_INCLUDE_DIR}"
        IMPORTED_LOCATION "${TESTU01_PROBDIST}"
    )
    set_target_properties(TestU01::MyLib PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${TESTU01_INCLUDE_DIR}"
        IMPORTED_LOCATION "${TESTU01_MYLIB}"
    )
endif ()

set(TESTU01_LIBRARIES TestU01::TestU01 TestU01::ProbDist TestU01::MyLib)
