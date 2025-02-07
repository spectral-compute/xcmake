include(CheckLanguage)

function(check_language LANG)
    xcmake_log_buffer_clear() # ensure that the only information dumped will be relevant to this command
    _check_language(${LANG})
    if (NOT CMAKE_${LANG}_COMPILER)
        message(BOLD_YELLOW "Failed check for language ${LANG}, dumping configure log:")
        xcmake_log_buffer_dump()
    endif()
endfunction()
