# Automatically generate project-specific flags for documentation and tests

# Add global options for documentation and build tests. Project-specific toggles should
# default to these values
option(XCMAKE_ENABLE_DOCS "Generate documentation for all projects" ON)
option(XCMAKE_ENABLE_TESTS "Build unit tests for all projects" ON)

# Add project-specific toggles
string(TOUPPER ${PROJECT_NAME} NAME) # Get it uppercase to remain consistent
option(${NAME}_ENABLE_DOCS "Build the documentation for this project" ${XCMAKE_ENABLE_DOCS})
option(${NAME}_ENABLE_TESTS "Build the units tests for this project" ${XCMAKE_ENABLE_TESTS})

# Aborts the calling function if the desired docs aren't turned on
# PROJECT - The project flag to check
# SOURCE - Doc type (eg. "doxygen") or a docs library (eg.
macro(ensure_docs_enabled)
    set(oneValueArgs PROJECT TYPE)
    cmake_parse_arguments("f" "" "${oneValueArgs}" "" ${ARGN})

    string(TOUPPER ${f_PROJECT} PROJECT_U)
    if (NOT ${PROJECT_U}_ENABLE_DOCS)
        message_colour(STATUS BoldYellow
                "Not building ${f_TYPE} for ${NAME} because ${PROJECT_U}_ENABLE_DOCS == OFF")
        set(FLAGCHECK FALSE PARENT_SCOPE)
        return ()
    endif ()
endmacro()
