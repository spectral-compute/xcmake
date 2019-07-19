# Wrap the various find_* functions so we can choose whether or not we want to pollute the documentation portion
# of the cache.
# The default behaviour is changed so variables are cached as `INTERNAL` and hence omitted from `ccmake`'s output.

function(find_path OUTVAR)
    _find_path(${OUTVAR} ${ARGN})
    mark_as_advanced(${OUTVAR})
endfunction()

function(find_library OUTVAR)
    _find_library(${OUTVAR} ${ARGN})
    mark_as_advanced(${OUTVAR})
endfunction()

function(find_program OUTVAR)
    _find_program(${OUTVAR} ${ARGN})
    mark_as_advanced(${OUTVAR})
endfunction()
