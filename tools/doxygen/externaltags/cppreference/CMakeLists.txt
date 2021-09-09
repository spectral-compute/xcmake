# Download cppreference.com tags file. This is to make references to the STL link to cppreference.com. The link to this
# was found here: https://upload.cppreference.com/w/Special:ListFiles
include(ExternalData)
set(ExternalData_URL_TEMPLATES
        "https://upload.cppreference.com/mwiki/images/1/16/html_book_20190607.tar.xz")
externaldata_expand_arguments(cppreference_html_book CPPREFERENCE_HTML_BOOK
        "DATA{${XCMAKE_TOOLS_DIR}/doxygen/externaltags/cppreference/html_book_20190607.tar.xz}")
externaldata_add_target(cppreference_html_book)

# Extract the tag file from the downloaded file.
set(OUTPUT_TAG_FILE "${CMAKE_BINARY_DIR}/docs/tagfiles/cppreference.tag")
add_custom_command(
    OUTPUT "${OUTPUT_TAG_FILE}"
    COMMAND "${CMAKE_CURRENT_LIST_DIR}/extract.sh"
            "${CPPREFERENCE_HTML_BOOK}"
            "${OUTPUT_TAG_FILE}"
    COMMENT "Extracting cppreference tag file"
    DEPENDS "${CPPREFERENCE_HTML_BOOK}"
    DEPENDS "${CMAKE_CURRENT_LIST_DIR}/extract.sh"
)

# Create a target for the tagfile with the properties our Doxygen handling expects.
add_custom_target(cppreference_tagfile DEPENDS "${OUTPUT_TAG_FILE}")
set_target_properties(cppreference_tagfile PROPERTIES
    DOXYGEN_TAGFILE "${OUTPUT_TAG_FILE}"
    DOXYGEN_URL "https://en.cppreference.com/w/"
)
