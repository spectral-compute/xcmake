include(GetPrerequisites)

# Argument documentation
# CMAKE_ARGV3 - Full path to executable file
# CMAKE_ARGV4 - List of directories to search for prerequisites

set(EXECUTABLE_PATH ${CMAKE_ARGV3})
set(SEARCH_PATHS ${CMAKE_ARGV4})

# Unpack some parts of the executable path.
get_filename_component(EXE_BASENAME "${EXECUTABLE_PATH}" NAME_WE)
get_filename_component(EXE_DIR "${EXECUTABLE_PATH}" DIRECTORY)

# Create the dedicated symlink directory
set(SYMLINK_DIR "${EXE_DIR}/${EXE_BASENAME}_SYMLINKS")
file(MAKE_DIRECTORY "${SYMLINK_DIR}")

# Get all our dependencies
set(DEPENDENCIES "")
get_prerequisites("${EXECUTABLE_PATH}" DEPENDENCIES 1 1 "" "${SEARCH_PATHS}")

# Get full path to each dependency, and create a symbolic link from it to the executable's location
foreach(DEPENDENCY ${DEPENDENCIES})
    set(GET_PREREQUISITES_VERBOSE TRUE)
    gp_resolve_item("${EXECUTABLE_PATH}" ${DEPENDENCY} "" "${SEARCH_PATHS}" DEPENDENCY_PATH)

    # Create library symlinks:
    # - As siblings to the executable in the object tree, so it can be run there.
    # - In a special directory that is the target of an `install(DIRECTORY` command, so the executable can be run
    #   post-installation, too.
    execute_process(COMMAND ln -sf "${DEPENDENCY_PATH}" "${EXECUTABLE_PATH}/${DEPENDENCY}")
    execute_process(COMMAND ln -sf "${DEPENDENCY_PATH}" "${EXECUTABLE_PATH}/${EXE_BASENAME}_SYMLINKS/${DEPENDENCY}")
endforeach()
