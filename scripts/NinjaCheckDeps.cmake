if ("${CMAKE_GENERATOR}" STREQUAL "Ninja")
    option(XCMAKE_CHECK_MISSING_DEPS "Run `ninja -t missingdeps` (check deps log dependencies on generated files)" ON)
endif()

if (XCMAKE_CHECK_MISSING_DEPS)
    set(STAMP ninja-dep-check.stamp)
    add_custom_command(
        OUTPUT ${STAMP}
        COMMENT "checking for missing deps on generated targets"
        COMMAND ninja -t missingdeps
        COMMAND cmake -E touch ${STAMP}
    )
    add_custom_target(ninja_dep_check ALL DEPENDS ninja-dep-check.stamp)
endif()
