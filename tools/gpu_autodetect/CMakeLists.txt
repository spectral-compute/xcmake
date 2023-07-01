cmake_minimum_required(VERSION 3.14)
project(gpu_autodetect)

find_package(CUDA 8.0 REQUIRED)
add_executable(gpu_autodetect main.cpp)
target_link_libraries(gpu_autodetect PRIVATE ${CUDA_LIBRARIES})
target_include_directories(gpu_autodetect PRIVATE ${CUDA_INCLUDE_DIRS})
