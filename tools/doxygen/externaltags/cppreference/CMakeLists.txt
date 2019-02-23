# Download cppreference.com tags file. This is to make references to the STL link to cppreference.com.
include(ExternalData)
set(ExternalData_URL_TEMPLATES
        "https://upload.cppreference.com/mwiki/images/f/f8/cppreference-doxygen-web.tag.xml")
ExternalData_Expand_Arguments(cppreference_data STL_TAG_FILE
        "DATA{${XCMAKE_TOOLS_DIR}/doxygen/externaltags/cppreference/cppreference-doxygen-web.tag.xml}")
set(STL_TAG_FILE "${STL_TAG_FILE}" CACHE INTERNAL "")
message(${STL_TAG_FILE})
ExternalData_Add_Target(cppreference_data)
