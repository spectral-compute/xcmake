# Make an executable target with google benchmark support. Google benchmark, Gtest, and associated crap is automatically
# added, and the target installed to the test prefix.
include(externals/GoogleBenchmark)

function(add_gbench_executable TARGET)
    set(flags CUSTOM_MAIN)
    cmake_parse_arguments(gt "${flags}" "" "" ${ARGN})

    add_test_executable(${TARGET} ${gt_UNPARSED_ARGUMENTS})

    if(NOT "${gt_CUSTOM_MAIN}")
        target_link_libraries(${TARGET} PRIVATE benchmark_main)
    endif()

    target_link_libraries(${TARGET} PRIVATE benchmark gtest)
endfunction()
