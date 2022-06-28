cmake_minimum_required(VERSION 3.19)
find_package(xcmake)
project(Simple)

add_executable(simple "${CMAKE_CURRENT_LIST_DIR}/main.cpp")
