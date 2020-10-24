# Do stuff common to all test targets.

# On Windows, the lack of any RPATH functionality requires executables and DLLs to be in the same path or the DLL can't be found
if (WIN32)
    default_cache_value(XCMAKE_TEST_INSTALL_PREFIX "./")
else ()
    default_cache_value(XCMAKE_TEST_INSTALL_PREFIX "test/")
endif()

macro(configure_test_target TARGET)
    install(
        TARGETS ${TARGET}
        RUNTIME DESTINATION ${XCMAKE_TEST_INSTALL_PREFIX}${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${XCMAKE_TEST_INSTALL_PREFIX}${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${XCMAKE_TEST_INSTALL_PREFIX}${CMAKE_INSTALL_LIBDIR}
    )

    # Tune the warnings that nobody cares about in test code down a wee bit.
    target_optional_compile_options(${TARGET} PRIVATE
        -Wno-weak-vtables
        -Wno-missing-variable-declarations
    )

    set_property(TARGET ${TARGET} APPEND PROPERTY INSTALL_RPATH "$ORIGIN/../../lib")
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
        # Install the thing
        install(PROGRAMS ${FILE} DESTINATION ${XCMAKE_TEST_INSTALL_PREFIX}${CMAKE_INSTALL_BINDIR})
    endif ()
endfunction()
