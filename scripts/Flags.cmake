# Automatically generate project-specific flags for documentation and tests

# Add global options for documentation and build tests. Project-specific toggles should
# default to these values
option(XCMAKE_ENABLE_DOCS "Generate documentation for all projects" ON)
option(XCMAKE_ENABLE_TESTS "Build unit tests for all projects" ON)

# Add project-specific toggles
string(TOUPPER ${PROJECT_NAME} NAME) # Get it uppercase to remain consistent
option(${NAME}_ENABLE_DOCS "Build the documentation for this project" ${XCMAKE_ENABLE_DOCS})
option(${NAME}_ENABLE_TESTS "Build the units tests for this project" ${XCMAKE_ENABLE_TESTS})

# Function to check a given project for flag state
# INPROJECT - The project flag to check
# DOCTYPE - Set at callsite for feedback purposes. Examples would be "DOXYGEN" or "specregex_internal"
# FLAGCHECK - A variable acting as a boolean return to get the parent scope to abort if needed
function(check_doc_flags INPROJECT DOCTYPE FLAGCHECK)
    string(TOUPPER ${INPROJECT} INPROJECT_U)
    if(NOT ${INPROJECT_U}_ENABLE_DOCS)
        message_colour(STATUS BoldYellow
                       "Not building ${DOCTYPE} for ${NAME} because ${INPROJECT_U}_ENABLE_DOCS == OFF")
        set(FLAGCHECK FALSE PARENT_SCOPE)
        return()
    endif()
endfunction(check_doc_flags)
