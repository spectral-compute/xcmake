function(get_git_version OUT)
    find_program(GIT_EXE git REQUIRED)
    mark_as_advanced(GIT_EXE)

    execute_process(
        COMMAND ${GIT_EXE} describe --tags --always
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE STDOUT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY
    )
    set(${OUT} ${STDOUT} PARENT_SCOPE)
endfunction()

function(get_git_depth OUT)
    find_program(GIT_EXE git REQUIRED)
    mark_as_advanced(GIT_EXE)

    execute_process(
        COMMAND ${GIT_EXE} rev-list HEAD --count
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE STDOUT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY
    )
    set(${OUT} ${STDOUT} PARENT_SCOPE)
endfunction()
