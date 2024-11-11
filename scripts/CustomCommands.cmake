# Override `add_custom_command()` to add `VERBATIM` in all cases.
# The documentation literally says:
#
#   Use of VERBATIM is recommended as it enables correct behavior. When VERBATIM is not given the behavior is platform
#   specific because there is no protection of tool-specific special characters.
#
# This is very silly. Let's just eliminate the possibility of making this mistake.
function (add_custom_command)
    # For maximum infuriation, cmake now rejects VERBATIM when combined with APPEND, since it's a no-op
    # (you use VERBATIM in the first call, and the APPEND calls just follow on). So: more madness required
    # to sort _that_ out.
    list(FIND ARGV APPEND VERB_FOUND)
    if (VERB_FOUND STREQUAL "-1")
        _add_custom_command(${ARGN} VERBATIM)
    else()
        _add_custom_command(${ARGN})
    endif()
endfunction()
