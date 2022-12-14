# Make an executable target with gtest support. Gtest and associated crap is automatically
# added, and the target installed to the test prefix.
#
# @param CUSTOM_MAIN Pass flag if you have defined your own main. Otherwise the default gtest
#                    main is used.
include(externals/GoogleTest)

function(add_gtest_executable TARGET)
    set(flags CUSTOM_MAIN)
    cmake_parse_arguments(gt "${flags}" "" "" ${ARGN})

    add_test_executable(${TARGET} ${gt_UNPARSED_ARGUMENTS})

    # Link in gmock's main function if we need to
    # We need to do this first, as when they're static, the linker does things in order, and gmock_main
    # depends on gmock
    if(NOT "${gt_CUSTOM_MAIN}")
        target_link_libraries(${TARGET} PRIVATE gmock_main)
    endif()

    target_link_libraries(${TARGET} PRIVATE gmock gtest)
endfunction()
