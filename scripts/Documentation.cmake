# Global options for the build system.

# Aborts the calling function if the desired docs aren't turned on
# PROJECT - The project flag to check
# SOURCE - Doc type (eg. "doxygen") or a docs library.
macro(ensure_docs_enabled)
    if (NOT ${XCMAKE_ENABLE_DOCS})
        message(BOLD_YELLOW "Skipping documentation generation")
        return ()
    endif ()
endmacro()
