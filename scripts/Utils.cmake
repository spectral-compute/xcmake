# Globally-available utility functions, included everywhere.
macro(default_value NAME VALUE)
    if (NOT DEFINED ${NAME})
        set(${NAME} ${VALUE})
    endif()
endmacro()
