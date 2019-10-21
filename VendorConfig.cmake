# Configruation of who is using xcmake. Used to populate sensible defaults for cpack, logo usage, etc.

# The name of your organisation.
set(XCMAKE_COMPANY_NAME "Spectral Compute LTD")

# The organisation's website.
set(XCMAKE_COMPANY_WEBSITE "https://spectralcompute.co.uk")

# A path-friendly veriant of your organisation name.
set(XCMAKE_COMPANY_PATH_NAME "Spectral Compute")

# A path to your organisation's logo. The name should be given without a file extension, and you must provide both a
# png and an svg.
set(XCMAKE_COMPANY_LOGO_PATH "${XCMAKE_RESOURCE_DIR}/logo_nowords")

# A directory containing `banner.png` and `dialog.png`, used to style the WIX installer (if used).
set(XCMAKE_WIX_INSTALLER_BRANDING "${XCMAKE_RESOURCE_DIR}/wix_branding")

# An email address your organisation can be reached for help.
set(XCMAKE_COMPANY_HELP_EMAIL "help@spectralcompute.co.uk")
