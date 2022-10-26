include(GNUInstallDirs)

# Builds on Cmake's built-in `UseSWIG` to add a few niceties:
# - Automatically harvest properties from the backing library
# - Automatically link against needed interpreters (eg. python's libraries when you ask for python)
# - Various --please-work settings.
function(add_swig_bindings_to TARGET)
    set(flags)
    set(oneValueArgs)
    set(multiValueArgs LANGUAGES SOURCES)
    cmake_parse_arguments("h" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    find_package(SWIG)
    include(UseSWIG)
    set(SWIG_SOURCE_FILE_EXTENSIONS ".i" ".swg")
    set(CMAKE_SWIG_FLAGS "-doxygen")

    # UGH WHY ARE THESE SOURCE PROPERTIES.
    foreach (ARG IN LISTS h_SOURCES)
        set_source_files_properties(${ARG} PROPERTIES
            CPLUSPLUS ON
            SWIG_USE_TARGET_INCLUDE_DIRECTORIES ON
        )
    endforeach()

    set(SWIG_INTERFACE_DIR ${CMAKE_CURRENT_BINARY_DIR}/swig)
    foreach (LANG IN LISTS h_LANGUAGES)
        set(SWIG_GENSRC_DIR ${CMAKE_CURRENT_BINARY_DIR}/swiggen_${LANG})
        file(MAKE_DIRECTORY ${SWIG_INTERFACE_DIR}/${LANG})
        file(MAKE_DIRECTORY ${SWIG_GENSRC_DIR})
        install(DIRECTORY ${SWIG_INTERFACE_DIR}/${LANG}
            DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}
        )

        set(SWIG_TARGET ${TARGET}_${LANG})
        swig_add_library(${SWIG_TARGET}
            TYPE USE_BUILD_SHARED_LIBS
            LANGUAGE ${LANG}
            OUTPUT_DIR ${SWIG_INTERFACE_DIR}/${LANG}
            OUTFILE_DIR ${SWIG_GENSRC_DIR}
            SOURCES ${h_SOURCES}
        )
        set_target_properties(${SWIG_TARGET} PROPERTIES WERROR OFF)
        target_compile_options(${SWIG_TARGET} PRIVATE
            # the goal is to turn off warnings introduced by SWIG, but leave enough enabled that actual issues with the input
            # program headers will get shown.
            -Wno-zero-as-null-pointer-constant
            -Wno-unused-macros
            -Wno-used-but-marked-unused
            -Wno-extra-semi-stmt
            -Wno-unused-parameter
            -Wno-shadow
        )

        target_link_libraries(${SWIG_TARGET} PRIVATE ${TARGET})

        # Language-specific magic goes here.
        if (${LANG} STREQUAL python)
            # For Python bindings, we need Python libraries and stuff.
            find_package(Python COMPONENTS Development.Module REQUIRED)
            target_link_libraries(${SWIG_TARGET} PRIVATE Python::Module)
        endif()
    endforeach()
endfunction()
