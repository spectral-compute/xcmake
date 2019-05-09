# Provide uppercase and lowercase versions of PROJECT_NAME
string(TOUPPER ${PROJECT_NAME} XCMAKE_PROJECT_NAME_UPPER)
string(TOLOWER ${PROJECT_NAME} XCMAKE_PROJECT_NAME_LOWER)

## Include the rest of xcmake, for convenience.
include(Properties)
include(Flags)
