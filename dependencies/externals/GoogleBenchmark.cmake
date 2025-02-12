include_guard(GLOBAL)
include(ExternalProj)
include(externals/GoogleTest)

option(XCMAKE_SYSTEM_GBENCH "Use system gbench rather than build our own" On)
mark_as_advanced(XCMAKE_SYSTEM_GTEST) # Should really just be using the find-or-build-package system...

option(GBENCH_TAG "Specify the tag to checkout from the gbench repo (if SYSTEM_GBENCH is off)" v1.9.1 STRING)
mark_as_advanced(GBENCH_TAG)

if(SYSTEM_GBENCH)
    find_package(benchmark)
else()
    add_external_project(googlebench
        GIT_REPOSITORY    https://github.com/google/benchmark
        GIT_TAG           main
        CMAKE_ARGS        -DCMAKE_BUILD_TYPE=Release -DBENCHMARK_USE_BUNDLED_GTEST=Off
        LIBRARIES         benchmark benchmark_main
    )

    if (BUILD_SHARED_LIBS)
        install(TARGETS benchmark EP_TARGET)
        target_compile_definitions(benchmark INTERFACE "GTEST_LINKED_AS_SHARED_LIBRARY=1")
    endif()
endif()
