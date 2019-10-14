# Global options for the build system.

# Toggle all documentation/tests
option(XCMAKE_ENABLE_DOCS "Generate documentation for all projects" ON)
option(XCMAKE_ENABLE_TESTS "Build unit tests for all projects" ON)

# Aborts the calling function if the desired docs aren't turned on
# PROJECT - The project flag to check
# SOURCE - Doc type (eg. "doxygen") or a docs library.
macro(ensure_docs_enabled)
    if (NOT ${XCMAKE_ENABLE_DOCS})
        message(BOLD_YELLOW "Skipping documentation generation")
        return ()
    endif ()
endmacro()

# Configure a list of trademarks to sanitise the documentation for.
option(XCMAKE_SANITISE_TRADEMARKS "A list of trademarks to scan headers/documentation for. The last symbol of the word shall be the appropriate special symbol. Formatted as a list of <word>:<I<owner> pairs" "" STRING)
