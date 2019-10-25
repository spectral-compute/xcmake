find_package(CUDA 8.0 REQUIRED)
list(GET CUDA_INCLUDE_DIRS 0 CUDA_INCLUDE_DIR)
add_custom_target(nvcuda)

# We want to be able to cross-reference NVIDIA's CUDA documentation (which _is_ doxygen). Unfortunately, they
# obfuscated their tag URLs, so we have to get a bit creative to make it work.

# First up, we preprocess the API header so it's actually, you know, correct.
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/docs/nvcuda/")
set(INTERMEDIATE_HEADER "${CMAKE_BINARY_DIR}/docs/nvcuda/cuda_runtime_api.h")

add_custom_command(
    OUTPUT "${INTERMEDIATE_HEADER}"
    COMMAND "${CMAKE_CURRENT_LIST_DIR}/preprocess.sh" "${CUDA_INCLUDE_DIR}" "${INTERMEDIATE_HEADER}"
    COMMENT "Generating unified NVIDIA CUDA API Header..."
    DEPENDS "${CUDA_INCLUDE_DIR}/cuda_runtime_api.h"
    DEPENDS "${CMAKE_CURRENT_LIST_DIR}/preprocess.sh"
    WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
)

add_custom_target(libnvcuda_intermediate_header
    DEPENDS "${INTERMEDIATE_HEADER}"
)


# Firstly, we run doxygen on the NVIDIA CUDA headers to generate a Doxygen tagfile (full of broken URLs)...
add_doxygen(nvcuda_doxygen
    INPUT_HEADERS "${INTERMEDIATE_HEADER}"
    NOINSTALL
)
get_target_property(OBFUSCATED_TAGFILE nvcuda_doxygen DOXYGEN_TAGFILE)

# ... and then we run the broken tagfile through an insane regex to fix the links, so we can plug it into our
# doxygen targets.
set(OBFUSCATED_TAGFILE "${OBFUSCATED_TAGFILE}")
set(OUTPUT_TAG_FILE "${CMAKE_BINARY_DIR}/docs/tagfiles/libnvcuda.tag")

add_custom_command(
    OUTPUT "${OUTPUT_TAG_FILE}"
    COMMAND "${CMAKE_CURRENT_LIST_DIR}/deobfuscate.sh" "${OBFUSCATED_TAGFILE}" "${OUTPUT_TAG_FILE}"
    COMMENT "Deobfuscating NVIDIA doxygen tag references..."
    DEPENDS "${OBFUSCATED_TAGFILE}"
    DEPENDS "${CMAKE_CURRENT_LIST_DIR}/deobfuscate.sh"
    WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
)

add_custom_target(libnvcuda_tag_file
    DEPENDS "${OUTPUT_TAG_FILE}"
)
