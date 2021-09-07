# Download cppreference.com tags file. This is to make references to the STL link to cppreference.com.
include(ExternalData)
set(ExternalData_URL_TEMPLATES
        "https://upload.cppreference.com/mwiki/images/f/f8/cppreference-doxygen-web.tag.xml")
externaldata_expand_arguments(cppreference_tagfile STL_TAG_FILE
        "DATA{${XCMAKE_TOOLS_DIR}/doxygen/externaltags/cppreference/cppreference-doxygen-web.tag.xml}")
externaldata_add_target(cppreference_tagfile)

set_target_properties(cppreference_tagfile PROPERTIES
    DOXYGEN_TAGFILE "${STL_TAG_FILE}"
    DOXYGEN_URL "https://en.cppreference.com/w/"
)
