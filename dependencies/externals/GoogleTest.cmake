include_guard(GLOBAL)
include(ExternalProj)

option(GTEST_TAG "Specify the tag to checkout the gtest fork to" main STRING)
mark_as_advanced(GTEST_TAG) # This option probably shouldn't exist at all...

include(ExternalProj)
include(FindThreads)

option(XCMAKE_SYSTEM_GTEST "Use system gtest rather than build our own" On)
mark_as_advanced(XCMAKE_SYSTEM_GTEST) # Should really just be using the find-or-build-package system...

set(GT_PRODUCTS gtest gmock gtest_main gmock_main)

if(XCMAKE_SYSTEM_GTEST)
    find_package(GTest REQUIRED)
    foreach (GT_PRODUCT IN LISTS GT_PRODUCTS)
        add_library(${GT_PRODUCT} INTERFACE)
        target_link_libraries(${GT_PRODUCT} INTERFACE GTest::${GT_PRODUCT})
    endforeach()
else()
    get_ep_url(GTEST_URL https://github.com/google/googletest.git googletest)
    add_external_project(googletest
        GIT_REPOSITORY    ${GTEST_URL}
        GIT_TAG           ${GTEST_TAG}
        CMAKE
        LIBRARIES         ${GT_PRODUCTS}
    )
    if (BUILD_SHARED_LIBS)
        install(TARGETS ${GT_PRODUCTS} EP_TARGET)
    endif()

    target_link_libraries(gtest INTERFACE RAW ${CMAKE_DL_LIBS})

    foreach(LIB ${GT_PRODUCTS})
        if(${BUILD_SHARED_LIBS})
            target_compile_definitions(${LIB} INTERFACE "GTEST_LINKED_AS_SHARED_LIBRARY=1")
        endif()

        # Googletest depends on pthread, so we need to link that in for the case of building googletest statically
        target_link_libraries(${LIB} INTERFACE Threads::Threads)
    endforeach()
endif()
