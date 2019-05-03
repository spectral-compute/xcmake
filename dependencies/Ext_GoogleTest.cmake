option(GTEST_TAG "Allow user to set the GTEST external project's checkout tag" "master")

AddExternalProject(googletest
  GIT_REPOSITORY    git@gitlab.com:spectral-ai/engineering/thirdparty/googletest
  GIT_TAG           ${GTEST_TAG}
  CMAKE             TRUE
  STATIC_LIBRARIES  gtest gmock gtest_main gmock_main
)
