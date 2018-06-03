# XCmake

XCMake is a set of scripts to make working with cmake more convenient.

## CUDA Support

Select GPU target(s) with `-DXCMAKE_GPUS=x,y,z`. Arguments can be NVIDIA targets (eg `sm_61`) or AMD ones.
Mixing the two will work iff we've added that feature to the compiler yet.

`add_cuda_library()` and `add_cuda_executable()` are provided for conveniently creating targets that use CUDA.
This will hook up the CUDA runtime library appropriate for your chosen target GPU(s), and do a few obscure
things to make cmake not implode when asked to compile CUDA.

## Doxygen integration

Add your headers as a "header target" like this:

```cmake
add_headers(spec_includes
    HEADER_PATH ${CMAKE_CURRENT_LIST_DIR}}/include
)
```

Add a Doxygen target like this:

```cmake
add_doxygen(spec_doxygen
    LAYOUT_FILE ${CMAKE_CURRENT_LIST_DIR}/DoxygenLayout.xml
    HEADER_TARGETS spec_includes
)
```

Doxygen will be fed all headers specified by the given `HEADER_TARGETS`. You may also specify `DOXYFILE`,
however stealing the template from `speclib` is highly recommended as a starting point.

## [Uniform Export](./scripts/Export.cmake)

CMake's export mechanism is pretty confusing. With xcmake, simply do:
```cmake
export_project(NameOfMyLibrary VERSION 1.2.3)
```

Where `NameOfMyLibrary` is all of:

- The target name of the thing to export
- The name you want to export it as.
- The name prefix of the *config files to produce after export.
- The prefix of the export macro to use (`NameOfMyLibrary_EXPORT`).
- The directory under `./lib/cmake` to install the export files.

It's unclear why you'd ever want these things to differ, soo...

## [Automatic external project binding](./scripts/ExternalProj.cmake)

`AddExternalProject` is a wrapper around ExternalProject_Add that provides `IMPORTED` target generation. The following
extra options are provided:
- STATIC_LIBRARIES
- DYNAMIC_LIBRARIES
- EXECUTABLES

These describe the outputs of the external project build. `IMPORTED` targets will be generated with those names,
pointing to those artefacts. You can then just `target_link_library()` against those to trigger the actual build of
the external project on demand.

The `BINARY_DIR`, `SOURCE_DIR`, `INSTALL_DIR`, and EXCLUDE_FROM_ALL parameters of `ExternalProject_Add` are overridden.

Some additional conveniences are provided: cross-compilation flags from this cmake build are propagated
(toolchain_file, build_type, compiler). You must provide at least _some_ value for `CMAKE_ARGS` to exploit this.

## [GoogleTest integration](./scripts/GTest.cmake)

`add_gtest_executable()` and `add_gtest_library()` are convenient functions for creating googletest libraries or
executables.

## [Include Guards](./scripts/IncludeGuard.cmake)

Both file-scope and target-scope include guard mechanisms are provided.

## [Coloured Logging](./scripts/Log.cmake)

Constants are provided for ANSI colour codes, and a `message_colour` function provided:
```cmake
message_colour(STATUS BoldRed "THE WORLD IS ON FIRE")

# Warnings are automatically coloured BoldYellow, errors BoldRed, etc.
message(WARNING "Oh noes")
```

## Dynamic Binding

```cmake
function(foo)
    # Something interesting
endfunction()

function(bar)
    # Something interesting
endfunction()


set(MY_VAR foo)
dynamic_call(${MY_VAR}) # Calls foo(). Args are forwarded to foo(), if given.
```

This is almost suicidally insane, but is occasionally helpful.

## New Target Properties

Several features are provided by defining new target properties.

Many of CMake's target properties have a corresponding global variable `CMAKE_FOO` which sets the default value of the
`FOO` target property for all targets created in the future. The following all have a similar mechanism, except the
prefix is `XCMAKE_FOO`.

For example, to set the `SANITISER` property to `"Address"` for all targets by default, you could pass
`-DXCMAKE_SANITISER=Address` on the command line. Or you could use a `set()` call somewhere in your cmake script to
apply it only to some subset of your targets. Or you could use `set_target_property()` to set it precisely.

#### `CLANG_TIDY`: Bool

If true, the target is built with [clang-tidy](https://clang.llvm.org/extra/clang-tidy/). All warnings are treated as
errors.

#### `STRIP`: Bool

Strip the output binary. On by default if `CMAKE_BUILD_TYPE` is set to `Release`.

#### `VECTORISER_REMARKS`: Bool

Enable remarks from the LLVM loop vectoriser.

#### `SANITISER`: String

Enable a Clang sanitiser. Possible values are:

- None (Disables sanitisers)
- Address (For [`AddressSanitiser`](https://clang.llvm.org/docs/AddressSanitizer.html))
- Undefined (For [`UndefinedBehaviorSanitizer`](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html))
- Leak (For [`LeakSanitiser`](https://clang.llvm.org/docs/LeakSanitizer.html))
- Memory (For [`MemorySanitiser`](https://clang.llvm.org/docs/MemorySanitizer.html))
- Thread (For [`ThreadSanitiser`](https://clang.llvm.org/docs/ThreadSanitizer.html))

#### `SAFE_STACK`: Bool

Enable [SafeStack](https://clang.llvm.org/docs/SafeStack.html)
