# Do stuff common to all test targets.
macro(configure_test_target TARGET)
    install(
        TARGETS ${TARGET}
        RUNTIME DESTINATION test/bin
        LIBRARY DESTINATION test/lib
    )

    # Tune the warnings that nobody cares about in test code down a wee bit.
    target_compile_options(${TARGET} PRIVATE
        -Wno-weak-vtables
        -Wno-missing-variable-declarations
    )

    # TODO: Could be an overridden install(), but holy crap that's complicated.
    set_target_properties(${TARGET} PROPERTIES INSTALL_RPATH "$ORIGIN/../lib;$ORIGIN/../../lib")
endmacro()

# Add a test executable (installed under ./test)
function(add_test_executable TARGET)
    add_executable(${TARGET} ${ARGN} NOINSTALL)
    configure_test_target(${TARGET})
endfunction()

# Add a test library (installed under ./test)
function(add_test_library TARGET)
    add_library(${TARGET} ${ARGN} NOINSTALL)
    configure_test_target(${TARGET})
endfunction()

# Add a test shell-script target.
function(add_test_shell_script TARGET FILE)
    cmake_parse_arguments(args "NOINSTALL" "" "" ${ARGN})

    add_shell_script(${TARGET} ${FILE} ${ARGN} NOINSTALL)

    if (NOT args_NOINSTALL)
        # Install the thing.
        install(PROGRAMS ${FILE} DESTINATION test/bin)
    endif ()
endfunction()
