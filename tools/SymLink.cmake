include(GetPrerequisites)

# Argument documentation
# CMAKE_ARGV3 - Directory of executable
# CMAKE_ARGV4 - Name of executable
# CMAKE_ARGV5 - List of directories to search for prerequisites
# CMAKE_ARGV6 - Path to the top-level of the CMAKE build causing this script to run

# Create the executable's full path
set(EXE_PATH "${CMAKE_ARGV3}/${CMAKE_ARGV4}.exe")

# Create the dedicated symlink directory
set(SYMLINK_DIR ${CMAKE_ARGV3}/${CMAKE_ARGV4}_SYMLINKS)
file(MAKE_DIRECTORY ${SYMLINK_DIR})

# Get all our dependencies
set(DEPENDENCIES "")
get_prerequisites(${EXE_PATH} DEPENDENCIES 1 1 "" "${CMAKE_ARGV5}")

# Get full path to each dependency, and create a symbolic link from it to the executable's location
foreach(DEPENDENCY ${DEPENDENCIES})
    gp_resolve_item(${EXE_PATH} ${DEPENDENCY} "" "${CMAKE_ARGV5}" DEPENDENCY_PATH)

    # Create a symbolic link to that library at the executable's location
    execute_process(COMMAND ln -sf "${DEPENDENCY_PATH}" "${CMAKE_ARGV3}/${DEPENDENCY}")

    # TODO: Figure out if we can realistically use this. It has several pitfalls:
    # - MUST be run from an administrator shell or it just flat out fails
    # - On Windows, the symlinks created by this cannot be read by install(DIRECTORIES), but
    #   normal ones created by ln -sf can, and work fine...
    #file(CREATE_LINK "${DEPENDENCY_PATH}" "${CMAKE_ARGV3}/${DEPENDENCY}" SYMBOLIC)

    # Create a symbolic link to that library in a special subdirectory
    execute_process(COMMAND ln -sf "${DEPENDENCY_PATH}" "${CMAKE_ARGV3}/${CMAKE_ARGV4}_SYMLINKS/${DEPENDENCY}")
    #file(CREATE_LINK "${DEPENDENCY_PATH}" "${CMAKE_ARGV3}/${CMAKE_ARGV4}_SYMLINKS/${DEPENDENCY}" SYMBOLIC)
endforeach()
