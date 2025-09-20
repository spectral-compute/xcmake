# Wrap the various find_* functions so we can choose whether or not we want to
# pollute the documentation portion of the cache. The default behaviour is
# changed so variables are cached as `INTERNAL` and hence omitted from
# `ccmake`'s output.

# not necessary, but makes the behaviour of the search function overrides more
# immediately obvious, and skips code that doesn't need to run.
macro(xcmake_search_functions_return_if_outvar)
    if (${OUTVAR})
        return()
    endif()
endmacro()

# NO_CACHE means that OUTVAR must act as a regular variable declared in the
# caller's scope.
macro(xcmake_search_functions_handle_no_cache)
    if (arg_NO_CACHE)
        set(${OUTVAR} ${${OUTVAR}} PARENT_SCOPE)
    else()
        mark_as_advanced(${OUTVAR})
    endif()
endmacro()

# These could be implemented as macros, which would remove the want for the
# macros above, but since they can be implemented as functions, and the
# underlying wrappees are functions, best to also make them functions.
function(find_path OUTVAR)
    xcmake_search_functions_return_if_outvar()
    _find_path(${OUTVAR} ${ARGN})
    cmake_parse_arguments(arg "NO_CACHE" "" "" ${ARGN})
    xcmake_search_functions_handle_no_cache()
endfunction()

function(find_library OUTVAR)
    xcmake_search_functions_return_if_outvar()
    _find_library(${OUTVAR} ${ARGN})
    cmake_parse_arguments(arg "NO_CACHE" "" "" ${ARGN})
    xcmake_search_functions_handle_no_cache()
endfunction()

function(find_program OUTVAR)
    xcmake_search_functions_return_if_outvar()
    _find_program(${OUTVAR} ${ARGN})
    cmake_parse_arguments(arg "NO_CACHE" "" "" ${ARGN})
    xcmake_search_functions_handle_no_cache()
endfunction()
