# Yo dawg, I heard you liked xcmake.
include(scripts/Init.cmake)
project(XCMake
    VERSION 0.1.2
    DESCRIPTION "A library for building better build systems."
    HOMEPAGE_URL "https://spectralcompute.co.uk/"
)
include(XCMake)

message("If you're trying to *use* xcmake, then `add_subdirectory(xcmake)` is not what you want.")
add_custom_target(xcmake)

# This mostly exists so we can generate installers. Consequently, we do very little when not in packaging mode.
if (XCMAKE_PACKAGING)
    function (install_dir NAME)
        install(DIRECTORY ${NAME}/ COMPONENT ${PROJECT_NAME} DESTINATION ./${NAME})
    endfunction()
    function (install_file NAME)
        install(FILES ${NAME} COMPONENT ${PROJECT_NAME} DESTINATION ./)
    endfunction()

    install_dir(scripts)
    install_dir(toolchain)
    install_dir(tools)
    install_dir(dependencies)

    install_file(README.md) # TODO: Generate a proper manual...?
    install_file(VendorConfig.cmake)
    install_file(xcmake-config.cmake)

    cpack_add_component(${PROJECT_NAME} DESCRIPTION "${PROJECT_DESCRIPTION}")
endif()
