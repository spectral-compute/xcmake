# XCmake

XCMake is a set of scripts to make working with cmake more convenient.

## CUDA Support

Although CMake now has native support for CUDA, it's hardcoded to use nvcc. XCMake provides convenient CUDA support
that supports `clang` as well as `nvcc`, and allows targeting AMD GPUs if spectral-clang and amdcuda are present.

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
add_doxygen(spec
    LAYOUT_FILE ${CMAKE_CURRENT_LIST_DIR}/DoxygenLayout.xml
    HEADER_TARGETS spec_includes
)
```

Doxygen will be fed all headers specified by the given `HEADER_TARGETS`. You may also specify `DOXYFILE`,
however stealing the template from `speclib` is highly recommended as a starting point. See speclib for a more
comprehensive example of this feature in use.

## [Uniform Export](./scripts/Export.cmake)

CMake's export mechanism is pretty confusing. With XCmake, simply do:

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

`add_external_project` is a wrapper around ExternalProject_Add that provides `IMPORTED` target generation. The following
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
dynamic_call(${MY_VAR} some_arg) # Calls foo(some_arg).
```

This is almost suicidally insane, but is occasionally helpful.

## New Target Properties

Several features are provided by defining new target properties.

Many of CMake's target properties have a corresponding global variable `CMAKE_FOO` which sets the default value of the
`FOO` target property for all targets created in the future. The following all have a similar mechanism, except the
prefix is `XCMAKE_FOO`.

For example, to set the default value of the `SANITISER` property to `"Address"`, you could pass
`-DXCMAKE_SANITISER=Address` on the command line.

#### `ASSERTIONS`: Bool

Default: *OFF*

Flag to enable speclib-powered assertions.

Also sets `-ftrapv`.

#### `CLANG_TIDY`: Bool

Default: *OFF*

If true, the target is built with [clang-tidy](https://clang.llvm.org/extra/clang-tidy/). All warnings are treated as
errors.

#### `CUDA`: Bool

Default: *OFF*

Enable CUDA support. Typically you'll want to use `add_cuda_executable` or `add_cuda_library` instead. This property
is occasionally useful to query if you're writing a CMake function and want to check if a given target is CUDA-enabled.

#### `CUDA_REMARKS`: Bool

Default: *OFF*

Enable `spectral-clang`'s enhanced CUDA backend diagnostics. These should not usually be used if
`CMAKE_BUILD_TYPE` = `Debug` because doing so will usually produce many false positives caused by the optimiser being
turned off.

#### `CUDA_TOOL_EXT`: Bool

Default: *OFF*

Enable CUDA tooling extensions.

For NVIDIA targets, this adds NVTX. For AMD, it adds our compatible library (which may contain some no-op
implementations, depending on how far AMD have gotten with their profiler APIs just yet...)

#### `DEBUG_INFO`: Bool

Default: `CMAKE_BUILD_TYPE` == `Debug`

Include debug information in the binary for this target?

This is mainly useful if you want to selectively enable debug info for some targets without changing `CMAKE_BUILD_TYPE`.

#### `INCLUDE_WHAT_YOU_USE`: Bool

Default: *OFF*

Run the `include-what-you-use` tool on this target.

This differs from CMake's native support for IWYU by adding support for CUDA. Using CMake's native support on
CUDA-enabled targets results in it never finding any problems. XCMake's version will work, but errors in CUDA files
may be printed twice (since the tool is run separately for host and device compilation).

#### `OPT_LEVEL`: Bool

Optimisation level to use for the target.

The default is selected based on `CMAKE_BUILD_TYPE`. In addition to setting `-O`, this adjusts some CUDA-specific flags
such as `-fcuda-flush-denormals-to-zero` (which is enabled whenever unsafe optimisations are enabled).

Possible values:
- `none`: No optimisation.
- `size`: Optimise for size.
- `debug`: Optimise for debugging
- `safe`: Perform safe optimisations (conceptually similar to `-O3`)
- `unsafe`: Perform unsafe optimisations (conceptually similar to `-Ofast`, but more exhaustive).

#### `SAFE_STACK`: Bool

Default: *OFF*

Enable [SafeStack](https://clang.llvm.org/docs/SafeStack.html)

#### `SANITISER`: String

Default: *None*

Enable a Clang sanitiser. Possible values are:

- None (Disables sanitisers)
- Address (For [`AddressSanitiser`](https://clang.llvm.org/docs/AddressSanitizer.html))
- Undefined (For [`UndefinedBehaviorSanitizer`](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html))
- Leak (For [`LeakSanitiser`](https://clang.llvm.org/docs/LeakSanitizer.html))
- Memory (For [`MemorySanitiser`](https://clang.llvm.org/docs/MemorySanitizer.html))
- Thread (For [`ThreadSanitiser`](https://clang.llvm.org/docs/ThreadSanitizer.html))

#### `SOURCE_COVERAGE`: Bool

Default: *OFF*

Run LLVM's source coverage report generator on the target.

#### `STD_FILESYSTEM`: Bool

Default: *OFF*

Enable `std::filesystem` for this target.

#### `STRIP`: Bool

Default: *ON* iff `CMAKE_BUILD_TYPE` = `Release`

Strip the output binary.

#### `VECTORISER_REMARKS`: Bool

Default: *OFF*

Enable remarks from the LLVM loop vectoriser.
