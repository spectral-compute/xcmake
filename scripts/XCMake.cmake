# Include the TC _yet again_, because cmake drops some definitions during project() on some platforms,
# making some things undefined that should be empty-string...
include("${CMAKE_TOOLCHAIN_FILE}")

## Include the rest of xcmake, for convenience.
include(GTest)
include(Properties)
include(Documentation)
