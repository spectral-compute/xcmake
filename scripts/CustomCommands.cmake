# Override `add_custom_command()` to add `VERBATIM` in all cases.
# The documentation literally says:
#
#   Use of VERBATIM is recommended as it enables correct behavior. When VERBATIM is not given the behavior is platform
#   specific because there is no protection of tool-specific special characters.
#
# This is very silly. Let's just eliminate the possibility of making this mistake.
function (add_custom_command)
    _add_custom_command(${ARGN} VERBATIM)
endfunction()
