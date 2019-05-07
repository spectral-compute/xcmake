SubdirectoryGuard(GTest)

set(GTEST_TAG master CACHE STRING "Allow user to set the GTEST external project's checkout tag" "master")

AddExternalProject(googletest
  GIT_REPOSITORY    git@gitlab.com:spectral-ai/engineering/thirdparty/googletest
  GIT_TAG           ${GTEST_TAG}
  CMAKE_ARGS        -DBUILD_SHARED_LIBS=ON
  # Install libraries to /lib not /lib64. There's prooobably a more elegant solution?
  INSTALL_COMMAND make install && cp -RfT <INSTALL_DIR>/lib64 <INSTALL_DIR>/lib/ || true

  SHARED_LIBRARIES  gtest gmock gtest_main gmock_main
)
