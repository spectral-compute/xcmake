include(IncludeGuard)
IncludeGuard(Properties)

# Find all the property definition files.
file(
    GLOB PROPS
    LIST_DIRECTORIES true
    ${XCMAKE_SCRIPT_DIR}/properties/*
)

# Helper macros for the property definition fragments.
macro(define_xcmake_target_property NAME)
    set(flags FLAG)
    set(oneValueArgs BRIEF_DOCS FULL_DOCS DEFAULT)
    set(multiValueArgs)

    cmake_parse_arguments("tp" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    default_value(tp_DEFAULT OFF)
    default_value(tp_FULL_DOCS ${tp_BRIEF_DOCS})

    define_property(
        TARGET PROPERTY ${NAME}
        BRIEF_DOCS "${tp_BRIEF_DOCS}"
        FULL_DOCS "${tp_FULL_DOCS}"
    )

    if (NOT CACHE{XCMAKE_${NAME}})
        set(XCMAKE_${NAME} ${tp_DEFAULT} CACHE STRING "${tp_FULL_DOCS}")
    endif()

    # If it's a simple flag property, create the target.
    if (tp_FLAG)
        add_library(${NAME}_EFFECTS INTERFACE)
    endif()

    list(APPEND XCMAKE_TGT_PROPERTIES ${NAME})
endmacro()

macro(define_xcmake_global_property NAME)
    set(flags FLAG)
    set(oneValueArgs DEFAULT)
    set(multiValueArgs)

    cmake_parse_arguments("tp" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT tp_DEFAULT)
        set(tp_DEFAULT OFF)
    endif ()

    default_value(${NAME} ${tp_DEFAULT})
    list(APPEND XCMAKE_GLOBAL_PROPERTIES ${NAME})
endmacro()

# Include all the property definition fragments.
set(XCMAKE_TGT_PROPERTIES "")
set(XCMAKE_GLOBAL_PROPERTIES "")
foreach (_F IN LISTS PROPS)
    include("${_F}")
endforeach()
