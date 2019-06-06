IncludeGuard(GTest)

set(GTEST_TAG master CACHE STRING "Allow user to set the GTEST external project's checkout tag")
mark_as_advanced(GTEST_TAG) # This option probably shouldn't exist at all...

include(ExternalProj)

option(XCMAKE_SYSTEM_GTEST "Use system gtest rather than build our own" Off)
mark_as_advanced(XCMAKE_SYSTEM_GTEST) # Should really just be using the find-or-build-package system...

if (XCMAKE_SYSTEM_GTEST)
    find_package(GTest)
else ()
    AddExternalProject(googletest
      GIT_REPOSITORY    git@gitlab.com:spectral-ai/engineering/thirdparty/googletest
      GIT_TAG           ${GTEST_TAG}
      # Install libraries to /lib not /lib64. There's prooobably a more elegant solution?
      INSTALL_COMMAND make install && cp -RfT <INSTALL_DIR>/lib64 <INSTALL_DIR>/lib/ || true
      CMAKE_ARGS        -DBUILD_SHARED_LIBS=ON
      SHARED_LIBRARIES  gtest gmock gtest_main gmock_main
    )
endif ()

target_link_libraries(gtest INTERFACE RAW ${CMAKE_DL_LIBS})
