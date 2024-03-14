include_guard(GLOBAL)

include(ExternalProj)
include(externals/yaml-cpp)

externalproject_add(yavl
    GIT_REPOSITORY    git@gitlab.com:spectral-ai/engineering/thirdparty/yavl-cpp.git
    GIT_TAG           master
    CONFIGURE_COMMAND ""
    INSTALL_COMMAND ""
    BUILD_COMMAND     make
    BUILD_IN_SOURCE   ON
)
externalproject_get_property(yavl SOURCE_DIR)

add_library(yavl-cpp INTERFACE)
target_include_directories(yavl-cpp INTERFACE "${SOURCE_DIR}/include")
target_link_libraries(yavl-cpp INTERFACE yaml-cpp)

# The EP doesn't actually compile any imported libraries, so we have to do this:
add_dependencies(yavl-cpp yavl)

set(YAVL_COMPILER "${SOURCE_DIR}/yavl-compile")

function(add_yaml_schema)
    set(flags)
    set(oneValueArgs SCHEMA NAMESPACE)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments("g" "${flags}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    get_filename_component(HEADER_NAME "${g_SCHEMA}" NAME_WE)

    set(OUTDIR "${XCMAKE_GENERATED_DIR}/yvl_schemas")

    # Structs/enums go here
    set(DECL_OUT_PATH "${OUTDIR}/${HEADER_NAME}.hpp")

    # Serialisation templates go here.
    set(SERIALISER_OUT_PATH "${OUTDIR}/${HEADER_NAME}_serialisers.hpp")
    ensure_directory("${DECL_OUT_PATH}")

    set(NS_STR "")
    if (NOT "${g_NAMESPACE}" STREQUAL "")
        set(NS_STR --namespace;${g_NAMESPACE})
    endif()

    add_custom_command(
        OUTPUT "${DECL_OUT_PATH}" "${SERIALISER_OUT_PATH}"
        COMMAND "${YAVL_COMPILER}" --no-emit-databindings --emit-comparison-operators ${NS_STR} "${g_SCHEMA}" "${DECL_OUT_PATH}"
        COMMAND "${YAVL_COMPILER}" --no-emit-declarations ${NS_STR} "${g_SCHEMA}" "${SERIALISER_OUT_PATH}"
        DEPENDS "${g_SCHEMA}" ${YAVL_COMPILER}
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        COMMENT "Generating yaml schema"
    )

    add_custom_target(${HEADER_NAME}_yvl DEPENDS "${DECL_OUT_PATH}" "${SERIALISER_OUT_PATH}")
    add_dependencies(${HEADER_NAME}_yvl yavl-cpp)

    foreach (_T ${g_TARGETS})
        target_include_directories(${_T} PUBLIC "${OUTDIR}")
        target_link_libraries(${_T} PRIVATE yavl-cpp)
        add_dependencies(${_T} ${HEADER_NAME}_yvl)
    endforeach ()
endfunction()
