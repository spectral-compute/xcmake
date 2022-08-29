cmake_minimum_required(VERSION 3.19)
find_package(xcmake)
project(Simple)

add_headers(simple_headers HEADER_PATH include DEFINE_MACRO LIFE=42 UNDEFINE_MACRO HIDDEN COMPRESS)
