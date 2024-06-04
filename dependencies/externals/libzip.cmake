include_guard(GLOBAL)
include(ExternalProj)
include(externals/zlib)

if (WIN32)
    # The nullability attribute isn't consistently used on Windows. It also calls some Windows APIs with the wrong
    # pointer type.
    set(COMPILE_OPTIONS -Wno-nullability-completeness
                        -Wno-incompatible-function-pointer-types)
endif()

get_ep_url(LIBZIP_URL https://github.com/nih-at/libzip.git libzip)
add_external_project(libzip_proj
    GIT_REPOSITORY    ${LIBZIP_URL}
    GIT_TAG           v1.9.2
    C_FLAGS "${COMPILE_OPTIONS}"
    CMAKE_ARGS
        -DBUILD_SHARED_LIBS=OFF

        # Turn off many features we don't want.
        -DENABLE_WINDOWS_CRYPTO=OFF
        -DENABLE_GNUTLS=OFF
        -DENABLE_MBEDTLS=OFF
        -DENABLE_OPENSSL=OFF
        -DENABLE_WINDOWS_CRYPTO=OFF

        -DENABLE_BZIP2=OFF
        -DENABLE_LZMA=OFF
        -DENABLE_ZSTD=OFF

        -DBUILD_TOOLS=OFF
        -DBUILD_REGRESS=OFF
        -DBUILD_EXAMPLES=OFF
        -DBUILD_DOC=OFF

        # Find the zlib we built.
        -DCMAKE_POLICY_DEFAULT_CMP0074=NEW # Don't ignore <PKGNAME>_ROOT variables.
        -DZLIB_USE_STATIC_LIBS=ON
        -DZLIB_ROOT=${EP_INSTALL_DIR}

    STATIC_LIBRARIES
         zip
)
add_dependencies(libzip_proj z)
target_link_libraries(zip INTERFACE z)
