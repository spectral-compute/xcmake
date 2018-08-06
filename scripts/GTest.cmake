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

    # If gtest/gmock targets already exist, for any reason, just use them instead of searching for new ones.
    if (NOT TARGET gtest)
        # Find and add GoogleTest/GoogleMock.
        # GTest provides flawed import targets and no means to find gmock. Fun. So let's just do what they should
        # have done.
        find_library(gtest gtest)
        find_library(gmock gmock)
        find_library(gmock_main gmock_main)
        find_path(GMock_INC gmock/gmock.h)
        find_path(GTest_INC gtest/gtest.h)

        if (NOT gmock OR NOT GMock_INC)
            message(FATAL_ERROR "Unable to find gmock library or headers :(")
        endif()
        if (NOT gtest OR NOT GTest_INC)
            message(FATAL_ERROR "Unable to find gtest library or headers :(")
        endif ()
        if (NOT gmock_main)
            message(FATAL_ERROR "Unable to find gmock_main library :(")
        endif ()

        message_colour(STATUS Yellow "Found system Google Test for ${TARGET}:")
        message_colour(STATUS Yellow "  - gtest: ${gtest}")
        message_colour(STATUS Yellow "  - gmock: ${gmock}")
        message_colour(STATUS Yellow "  - gmock_main: ${gmock_main}")

        target_include_directories(${TARGET} SYSTEM PRIVATE ${GMock_INC} ${GTest_INC})
    else()
        set(gtest gtest)
        set(gmock gmock)
        set(gmock_main gmock_main)
        message_colour(STATUS Yellow "Using gtest fork for ${TARGET}.")
    endif()

    target_link_libraries(${TARGET} PRIVATE ${gtest} ${gmock})

    # Add the default main, if required. We must use the one from gmock, not gtest, since we want
    # features from gmock and the gtest main doesn't initialise gmock.
    if (NOT "${gt_CUSTOM_MAIN}")
        target_link_libraries(${TARGET} PRIVATE ${gmock_main})
    endif()
endfunction(add_gtest_executable)
