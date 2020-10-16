# Do stuff common to all test targets.
macro(configure_test_target TARGET)
    # Prefix all the install dirs with `./test`, except on Windows where the lack of RPATH
    # makes doing so an inconvenience.
    if (WIN32)
        set(OUTPUT_PREFIX "")
    else()
        set(OUTPUT_PREFIX "test/")
    endif()

    install(
        TARGETS ${TARGET}
        RUNTIME DESTINATION ${OUTPUT_PREFIX}${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${OUTPUT_PREFIX}${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${OUTPUT_PREFIX}${CMAKE_INSTALL_LIBDIR}
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
        install(PROGRAMS ${FILE} DESTINATION test/bin)
    endif ()
endfunction()
