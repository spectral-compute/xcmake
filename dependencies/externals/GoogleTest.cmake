include_guard(GLOBAL)

option(GTEST_TAG "Specify the tag to checkout the gtest fork to" master STRING)
mark_as_advanced(GTEST_TAG) # This option probably shouldn't exist at all...

include(ExternalProj)
include(FindThreads)

option(XCMAKE_SYSTEM_GTEST "Use system gtest rather than build our own" Off)
mark_as_advanced(XCMAKE_SYSTEM_GTEST) # Should really just be using the find-or-build-package system...

set(GT_PRODUCTS gtest gmock gtest_main gmock_main)

if(XCMAKE_SYSTEM_GTEST)
    find_package(GTest)
else()
    add_external_project(googletest
        GIT_REPOSITORY    git@gitlab.com:spectral-ai/engineering/thirdparty/googletest
        GIT_TAG           ${GTEST_TAG}
        CMAKE_ARGS        -DCMAKE_BUILD_TYPE=Release
        LIBRARIES         ${GT_PRODUCTS}
    )
endif()

target_link_libraries(gtest INTERFACE RAW ${CMAKE_DL_LIBS})

foreach(LIB ${GT_PRODUCTS})
    if(${BUILD_SHARED_LIBS})
        target_compile_definitions(${LIB} INTERFACE "GTEST_LINKED_AS_SHARED_LIBRARY=1")
    else()
        # Googletest depends on pthread, so we need to link that in for the case of building googletest statically
        target_link_libraries(${LIB} INTERFACE Threads::Threads)
    endif()
endforeach()
