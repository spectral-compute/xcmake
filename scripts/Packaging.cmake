# We can only package one thing at once. The top-level thing.
subdirectory_guard(${CMAKE_PROJECT_NAME}_PACKAGING)

default_cache_value(CPACK_VERBATIM_VARIABLES ON) # Would you like parse errors? No? Okay then.

##################
# Common options #
##################

# Some of these exist just so there's only one variable to affect several per-generator options..
default_value(XCMAKE_PACKAGE_ARCH x86_64) # TODO Slight laziness here. Should really be populated from toolchain file.

# CPack configuration variables. All of these can be overridden by projects.
default_value(CPACK_PACKAGE_VENDOR "${XCMAKE_COMPANY_NAME}")
default_value(CPACK_PACKAGE_CONTACT "${XCMAKE_COMPANY_HELP_EMAIL}")

default_value(CPACK_PACKAGE_ICON "${XCMAKE_COMPANY_LOGO_PATH}.svg")

default_value(CPACK_PACKAGE_INSTALL_DIRECTORY "${XCMAKE_COMPANY_PATH_NAME}")
default_value(CPACK_PACKAGE_CHECKSUM "SHA512")

default_value(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE.txt")

#########################
# RPM Generator options #
#########################

default_value(CPACK_RPM_PACKAGE_RELEASE_DIST ON)

# TODO: Everything about package dependencies... :D

#########################
# DEB Generator options #
#########################

if ("${XCMAKE_PACKAGE_ARCH}" STREQUAL "x86_64" OR "${XCMAKE_PACKAGE_ARCH}" STREQUAL "x86-64")
    default_value(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
else()
    default_value(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${XCMAKE_PACKAGE_ARCH})
endif()
default_value(CPACK_DEBIAN_PACKAGE_MAINTAINER ${XCMAKE_COMPANY_NAME})

if ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug" OR "${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo")
    set(CPACK_DEBIAN_DEBUGINFO_PACKAGE ON)
else()
    set(CPACK_DEBIAN_DEBUGINFO_PACKAGE OFF)
endif()

# TODO: Everything about package dependencies... :D

#############################
# Archive Generator options #
#############################

# None...

#########################
# WiX Generator options #
#########################
# For Windows. This is ostensibly less problematic than the NSIS generator).
set(CPACK_WIX_CMAKE_PACKAGE_REGISTRY "${PROJECT_NAME}")  # Allows discovery by `find_package()` on Windows.

# Wix wants a GUID that it'll use later to detect when a new package is updating an old one.
default_value(CPACK_WIX_UPGRADE_GUID ${XCMAKE_PROJECT_GUID})

default_value(CPACK_WIX_PRODUCT_ICON "${XCMAKE_COMPANY_LOGO_PATH}.png")
default_value(CPACK_WIX_UI_BANNER "${XCMAKE_WIX_INSTALLER_BRANDING}/banner.png")
default_value(CPACK_WIX_UI_DIALOG "${XCMAKE_WIX_INSTALLER_BRANDING}/dialog.png")

# If present, apply the project's WIXPatch. This allows manual tinkering with the absurd XML from which the
# installer is eventually generated.
if (EXISTS "${CMAKE_SOURCE_DIR}/WIXPatch.xml")
    default_value(CPACK_WIX_PATCH_FILE "${CMAKE_SOURCE_DIR}/WIXPatch.xml")
endif()

# Set default generator per-platform
if (WIN32)
    default_value(CPACK_GENERATOR "WIX")
elseif(APPLE)
    warning("Packaging skipped because nobody configured it for MacOS yet.")
elseif(UNIX)
    set(DEFAULT_UNIX_GENERATORS "TGZ")

    # We can'd do RPMs if this isn't in PATH, and the default behaviour of cpack is to just crash in that scenario.
    find_program(RPM_BUILD_EXE rpmbuild)

    if (RPM_BUILD_EXE)
        list(APPEND DEFAULT_UNIX_GENERATORS "RPM")
    else()
        warning("RPM packaging skipped because `rpmbuild` is not installed.")
    endif()

    default_value(CPACK_GENERATOR "${DEFAULT_UNIX_GENERATORS}")
elseif (NOT DEFINED CPACK_GENERATOR)
    warning(On "Packaging skipped because the target OS is not known.")
endif()

# Make sure WIX is installed.
if ("WIX" IN_LIST CPACK_GENERATOR)
    find_program(WIX_LIGHT_EXE light)
    find_program(WIX_CANDLE_EXE candle)

    if (WIX_LIGHT_EXE AND WIX_CANDLE_EXE)
    else()
        fatal_error("WIX is not installed, but WIX package generation was enabled.")
    endif()
endif()

# Including CPack creates the package target, but we only actually want to do this if the build is one that's suitable
# for packaging. Enabling tests typically hoovers up a lot of things we don't want to depend on, so:
if (XCMAKE_PACKAGING)
    include(CPack)
    include(CPackComponent)
endif()
