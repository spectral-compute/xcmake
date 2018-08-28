# Add a test executable (installed under ./test)
function(add_test_executable TARGET)
    add_executable(${TARGET} ${ARGN} NOINSTALL)

    install(
        TARGETS ${TARGET}
        RUNTIME DESTINATION test/bin
        LIBRARY DESTINATION test/lib
    )

    # TODO: Could be an overridden install(), but holy crap that's complicated.
    set_target_properties(${TARGET} PROPERTIES INSTALL_RPATH "$ORIGIN/../../lib")
endfunction()
