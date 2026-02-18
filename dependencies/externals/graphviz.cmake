include_guard(GLOBAL)
include(ExternalProj)

get_ep_url(GRAPHVIZ_URL https://gitlab.com/graphviz/graphviz.git graphviz)

add_external_project(graphviz_proj
    GIT_REPOSITORY ${GRAPHVIZ_URL}
    GIT_TAG        14.1.2

    # Autotools project; ensure all commands run from the source dir.
    CONFIGURE_COMMAND
        ${CMAKE_COMMAND} -E chdir <SOURCE_DIR> ./autogen.sh
        COMMAND ${CMAKE_COMMAND} -E chdir <SOURCE_DIR> ./configure
            --prefix=<INSTALL_DIR>
            --enable-static
            --disable-shared
            --with-included-ltdl
            --without-x
            --disable-swig
            --disable-tcl
            --disable-lua
            --disable-python
            --disable-ruby
            --disable-perl
            --disable-php
            CFLAGS=-O2\ -fPIC
            CXXFLAGS=-O2\ -fPIC

    BUILD_COMMAND
        ${CMAKE_COMMAND} -E chdir <SOURCE_DIR> $(MAKE) -j$ENV{CMAKE_BUILD_PARALLEL_LEVEL}

    INSTALL_COMMAND
        ${CMAKE_COMMAND} -E chdir <SOURCE_DIR> $(MAKE) install

    STATIC_LIBRARIES
        cgraph
        cdt
        pathplan
)

# Make imported targets carry the right transitive deps.
target_link_libraries(cgraph INTERFACE cdt pathplan m z dl)
