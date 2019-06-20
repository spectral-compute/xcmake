# This config file makes xcmake inclusion using find_package() just magically work, assuming
# the root directory is set in the environment xcmake_ROOT.
# Use of this requires cmake 3.15 however.
# Users of older cmake need to explicitly include the below files
cmake_policy(VERSION 3.15)

# Include pre-project initialization
set(CMAKE_PROJECT_INCLUDE_BEFORE "${CMAKE_CURRENT_LIST_DIR}/scripts/Init.cmake")

# Run the post-project initialization after project()
set(CMAKE_PROJECT_INCLUDE "${CMAKE_CURRENT_LIST_DIR}/scripts/XCMake.cmake")
