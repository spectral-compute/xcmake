include(CMakePackageConfigHelpers)

function(export_project)
    # The usual boilerplate to spit out and install the version and config file...
    set(OUTPATH ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME})
    write_basic_package_version_file(
        ${OUTPATH}/${PROJECT_NAME}Version.cmake
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY AnyNewerVersion
    )

    # Allows us to inject extra macros and stuff into the config file. We'll likely find a use
    # for this if our dependency tree gets more exciting. Also, make sure we keep @PACKAGE_INIT@ for
    # configure_package_config_file().
    set(EXTRA_CONFIG_MACROS
        "include(CMakeFindDependencyMacro)\n"
    )
    set(PACKAGE_INIT "@PACKAGE_INIT@")
    configure_file(
        ${PROJECT_SOURCE_DIR}/${PROJECT_NAME}Config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake.tmp
        @ONLY
    )

    # Config file.
    configure_package_config_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake.tmp
        ${OUTPATH}/${PROJECT_NAME}Config.cmake
        INSTALL_DESTINATION lib/cmake/${PROJECT_NAME}
    )

    install(FILES
        ${OUTPATH}/${PROJECT_NAME}Config.cmake
        ${OUTPATH}/${PROJECT_NAME}Version.cmake
        DESTINATION lib/cmake/${PROJECT_NAME}
    )

    export(EXPORT ${PROJECT_NAME} FILE "${CMAKE_CURRENT_BINARY_DIR}/generated/${PROJECT_NAME}Targets.cmake")
    install(EXPORT ${PROJECT_NAME} FILE ${PROJECT_NAME}Targets.cmake DESTINATION lib/cmake/${PROJECT_NAME})
endfunction()
