# Add a test executable (installed under ./test)
function(add_test_executable TARGET)
    add_executable(${TARGET} ${ARGN} NOINSTALL)

    install(
        TARGETS ${TARGET}
        RUNTIME DESTINATION test/bin
        LIBRARY DESTINATION test/lib
    )
endfunction()

# Make an executable target with gtest support. Gtest and associated crap is automatically
# added, and the target installed to the test prefix.
#
# @param CUSTOM_MAIN Pass flag if you have defined your own main. Otherwise the default gtest
#                    main is used.
function(add_gtest_executable TARGET)
    set(EXTRA_ARGS "${ARGN}")

    set(flags CUSTOM_MAIN)
    set(oneValueArgs)
    set(multiValueArgs)
    cmake_parse_arguments("gt" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    remove_argument(FLAG EXTRA_ARGS CUSTOM_MAIN)
    add_test_executable(${TARGET} ${EXTRA_ARGS})

    # Find and add GoogleTest/GoogleMock.
    # GTest provides nifty imported targets (which handle the threads dependency for us), but
    # gmock does not appear to...
    find_package(GTest REQUIRED)
    find_library(GMock_LIB gmock)
    find_path(GMock_INC gmock/gmock.h)
    if (NOT GMock_LIB OR NOT GMock_INC)
        message(FATAL_ERROR "Unable to find gmock library or headers :(")
    endif()

    # Add gmock include
    target_include_directories(${TARGET} SYSTEM PRIVATE ${GMock_INC})

    # Apply gtest imported targets (which hopefully take care of include paths for us...)
    target_link_libraries(${TARGET} PRIVATE GTest::GTest)

    # Add the default main, if required. We must use the one from gmock, not gtest, since we want
    # features from gmock and the gtest main doesn't initialise gmock.
    if (NOT "${gt_CUSTOM_MAIN}")
        find_library(GMock_MAIN gmock_main)
        if (NOT GMock_MAIN)
            message(FATAL_ERROR "Unable to find gmock_main library :(")
        endif()

        target_link_libraries(${TARGET} PRIVATE ${GMock_MAIN})
    endif()
endfunction(add_gtest_executable)
