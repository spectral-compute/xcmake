## Include the rest of xcmake, for convenience.

include(Properties)
include(Flags)
include(ExternalProj) # Can't be in Init.cmake because content such as CMAKE_STATIC_LIBRARY_SUFFIX are set by Project() call
include(GTest) # Depends on ExternalProj through Ext_GoogleTest.cmake
