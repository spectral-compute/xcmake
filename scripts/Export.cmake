include(CMakePackageConfigHelpers)

function(export_project NAME)
    cmake_parse_arguments("exp" "" "VERSION" "" ${ARGN})

    # The usual boilerplate to spit out and install the version and config file...
    set(OUTPATH ${CMAKE_CURRENT_BINARY_DIR}/${NAME})
    write_basic_package_version_file(
        ${OUTPATH}/${NAME}Version.cmake
        VERSION ${exp_VERSION}
        COMPATIBILITY AnyNewerVersion
    )

    # Allows us to inject extra macros and stuff into the config file. We'll likely find a use
    # for this if our dependency tree gets more exciting. Also, make sure we keep @PACKAGE_INIT@ for
    # configure_package_config_file().
    set(EXTRA_CONFIG_MACROS)
    set(PACKAGE_INIT "@PACKAGE_INIT@")
    configure_file(
        ${PROJECT_SOURCE_DIR}/${NAME}Config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}Config.cmake.tmp
        @ONLY
    )

    # Config file.
    configure_package_config_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}Config.cmake.tmp
        ${OUTPATH}/${NAME}Config.cmake
        INSTALL_DESTINATION lib/cmake/${NAME}
    )

    install(FILES
        ${OUTPATH}/${NAME}Config.cmake
        ${OUTPATH}/${NAME}Version.cmake
        DESTINATION lib/cmake/${NAME}
    )

    export(EXPORT ${NAME} FILE "${CMAKE_CURRENT_BINARY_DIR}/generated/${NAME}Targets.cmake")
    install(EXPORT ${NAME} FILE ${NAME}Targets.cmake DESTINATION lib/cmake/${NAME})
endfunction()
