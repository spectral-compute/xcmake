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

    set_target_properties(${TARGET} PROPERTIES INTERPROCEDURAL_OPTIMIZATION Off IS_TEST ON)

    if (APPLE)
        set(RPATH_ORIGIN "@loader_path")
    else()
        set(RPATH_ORIGIN "$ORIGIN")
    endif()
    set_property(TARGET ${TARGET} APPEND PROPERTY INSTALL_RPATH "${RPATH_ORIGIN}/../../lib")
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

# Organise the `build_tests` target for ctest test suites.
add_custom_target(build_tests)
function(add_test)
    cmake_parse_arguments("l" "${flags}" "NAME;WORKING_DIRECTORY" "CONFIGURATIONS;COMMAND" ${ARGN})

    # Test names aren't always targets, but if they are, we can collect the deps directly.
    if (TARGET ${l_NAME})
        add_dependencies(build_tests ${l_NAME})
    endif()

    # By default, ctest depends on the entire object tree, which is enormous.
    # This is deeply silly, because we only actually need the exeuctables. I claim
    # that people don't actually want this nonsense, so we override the options here.
    #
    # This becomes extra annoying due to this behaviour:
    # > If <command> specifies an executable target (created by add_executable()) it will
    # > automatically be replaced by the location of the executable created at build time.
    #
    # That's okay, we can fix that with enough cursed bullshit.
    set(NEW_CMD)
    foreach (_T IN LISTS l_COMMAND)
        if (TARGET ${_T})
            get_target_property(_T_TY ${_T} TYPE)
            if ("${_T_TY}" STREQUAL "EXECUTABLE")
                get_target_property(_NAME ${_T} RUNTIME_OUTPUT_NAME)
                if (_NAME)
                    list(APPEND NEW_CMD "./test/bin/${_NAME}")
                else()
                    list(APPEND NEW_CMD "./test/bin/${_T}")
                endif()
                add_dependencies(build_tests ${_T})
            else()
                list(APPEND NEW_CMD "${_T}")
            endif()
        else()
            list(APPEND NEW_CMD "${_T}")
        endif()
    endforeach()

    _add_test(
        NAME ${l_NAME}

        COMMAND ${NEW_CMD}
        WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}
    )
endfunction()
