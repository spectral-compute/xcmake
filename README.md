# XCmake

We observed that many projects end up solving the same set of cmake-related problems, usually imperfectly. We also
observed that cmake has some rather _unhelpful_ default behaviours.

XCMake is a set of scripts that aim to make using cmake more pleasant. It fixes things we consider bugs
in built-in functions, extends built-in functions to perform more validation, solves many common problems
so you never have to think about them, and adds a few new abstractions for things that commonly get people
tangled up.

- Less astonishing default behaviours for many of cmake's existing features.
- Doxygen integration
- Simplified generation of installers and packages for distribution.
- Coloured logging.
- Clang sanitiser integration.
- Clang-tidy integration.
- A simple, modular mechanism for adding custom properties.
- Pandoc integration.
- Extension of builtin cmake functions to add extra features (such as `install()` supporting `IMPORTED` targets).


## Extended built-ins

### `install()`

`install()` can now be applied to `IMPORTED` targets. This allows you to very straightforwardly copy all of your
dependencies to the install tree, which is mostly useful for Windows builds.

### `target_link_libraries()`

If you do `target_link_libraries(my_target something_that_does_not_exit)`, cmake will just optimistically stick
`-lsomething_that_does_not_exist` onto the linker command and hope for the best. Generally, that's not what you want.

With xcmake, `target_link_libraries` will emit a warning if you try to link to something that is not a target. You
should be creating imported targets for libraries you're importing, and you obviously you should be linking against your
own targets only after creating them.

If you wish to simply throw `-lfoo` onto the linker command, you can do that directly with cmake's `target_link_options()`
function (which explicitly serves the purpose of "please add this to the linker command line", as opposed to being a
very different operation that degrades to doing that if you make a mistake).

## Small things that "just work"

- `add_custom_command` always uses VERBATIM, so your shell scripts don't randomly break.
- Release executable stripping (can be disabled with target property)
- Helptext defined by `option()` calls is always added, not just for options that were not set on the command line.
- RPATH just works (respecting `LIBDIR` and friends).
- Target installation to standard locations (governed by the usual variables). Disable with `NOINSTALL` option.
- On implib platforms (ie. Windows), the install step also creates symlinks to all the needed dlls, and can optionally
  copy them.

## New Target Properties

Several features are provided by defining new target properties.

Many of CMake's target properties have a corresponding global variable `CMAKE_FOO` which sets the default value of the
`FOO` target property for all targets created in the future. The following all have a similar mechanism, except the
prefix is `XCMAKE_FOO`.

For example, to set the default value of the `SANITISER` property to `"Address"`, you could pass
`-DXCMAKE_SANITISER=Address` on the command line (which is how you'd do an asan build of your entire project).

#### `ASSERTIONS`: Bool

Default: *OFF*

Flag to enable speclib-powered assertions.

Also sets `-ftrapv`.

#### `BUILD_TYPE_AS_MACRO`: Bool

Default: *ON*

Provides the `CMAKE_BUILD_TYPE` to the C preprocessor. This adds these two preprocessor macro definitions:

```
-D${CMAKE_BUILD_TYPE}
-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
```

Note that, elsewhere, XCMake canonicalises `CMAKE_BUILD_TYPE` to eliminate case-sensivity issues.

#### `CLANG_TIDY`: Bool

Default: *OFF*

If true, the target is built with [clang-tidy](https://clang.llvm.org/extra/clang-tidy/). All warnings are treated as
errors.

#### `CUDA`: Bool

Default: *OFF*

Enable CUDA support. Typically you'll want to use `add_cuda_executable` or `add_cuda_library` instead. This property
is occasionally useful if you're writing a CMake function and want to check if a given target is CUDA-enabled.

#### `CUDA_REMARKS`: Bool

Default: *OFF*

Enable `spectral-clang`'s enhanced CUDA backend diagnostics. These should not usually be used if
`CMAKE_BUILD_TYPE` = `Debug` because doing so will usually produce many false positives caused by the optimiser being
turned off.

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

#### `LLVM_MODULES`: Bool

Default: *OFF*

Enable LLVM module support. This allows a target to be built *using* modules.

Note that LLVM modules are quite different from C++20 modules. Notably, they actually exist.

#### `OPT_LEVEL`: Bool

Optimisation level to use for the target.

The default is selected based on `CMAKE_BUILD_TYPE`. In addition to setting `-O`, this adjusts some CUDA-specific flags
such as `-fcuda-flush-denormals-to-zero`, which is enabled whenever unsafe optimisations are enabled, and fiddles with
some diagnostics that can be affected by optimisation level.

Possible values:
- `none`: No optimisation.
- `size`: Optimise for size.
- `debug`: Optimise for debugging
- `safe`: Perform safe optimisations (conceptually similar to clang's `-O3`)
- `unsafe`: Perform unsafe optimisations (conceptually similar to clang's `-Ofast`, but even more aggressive).

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

Enable `std::filesystem` for this target. Depending on which standard library and platform is in use, this can
require some custom linker flags and whatnot, which this property takes care of.

#### `LIBCXX`: Bool

Default: *OFF*

Use libc++ instead of the gnu standard library.

#### `STATIC_STDCXXLIB`: Bool

Default: *OFF*

Statically link the standard library (mostly useful for Windows executables).

#### `STRIP`: Bool

Default: *ON* iff `CMAKE_BUILD_TYPE` = `Release`

Strip the output binary.

#### `VECTORISER_REMARKS`: Bool

Default: *OFF*

Enable [remarks from the LLVM loop vectoriser](https://llvm.org/docs/Vectorizers.html#diagnostics).

#### `WERROR`: Bool

Default: *ON*

Warnings are errors.

## CUDA Support

Although CMake now has native support for CUDA, it's hardcoded to use nvcc. XCMake provides convenient CUDA support
that supports `clang` as well as `nvcc`.

Select GPU target(s) with `-DXCMAKE_GPUS=x,y,z`.

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

Header targets, by default, will be installed to [`${CMAKE_INSTALL_INCLUDEDIR}`](https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html).

Add a Doxygen target like this:

```cmake
add_doxygen(spec
    LAYOUT_FILE ${CMAKE_CURRENT_LIST_DIR}/DoxygenLayout.xml
    HEADER_TARGETS spec_includes
)
```

Doxygen will be fed all headers specified by the given header targets.

The Doxyfile template used is at `./tools/doxygen/Doxyfile.in`.

Optional arguments:

- `NOINSTALL`: Don't install the documentation. Mostly useful if you're only running Doxygen to generate a tagfile.
- `CUDA`: Automatically generate a de-obfuscated CUDA runtime API tagfile and include it in the build, so crossreferences
          to NVIDIA CUDA APIs automatically hyperlinkify.
- `INSTALL_DESTINATION`: Specify an alternative install destination.
- `DOXYFILE`: Specify an alternative Doxyfile template. You don't want this.
- `LAYOUT_FILE`: Specify an alternative Doxygen layout fail. The default is at `./tools/doxygen/DoxygenLayout.xml`.
- `DOXYFILE_SUFFIX`: Specify a target-specific file to append to the end of the Doxyfile, after generating it. This is
                     the proper way to add per-project configuration. Note that the Doxyfile language allows you to use
                     `+=` to append to lists, so you can use this to add things like lists of macros to expand.
- `LOGO`: Specify a path to a logo to include in the generated documentation.
- `SUBJECT`: Specify the library target for which documentation is being generated. This will automatically configure a
             few obscure Doxygen settings accordingly.
- `DEPENDS`: Specify other Doxygen targets to depend on. Tagfiles from those Doxygen targets will be assimilated into
             this one, so crossrefernces automatically hyperlinkify.

## `Pandoc` Integration

This allows you to create targets that compile your `README.md` files into beautiful documentation websites.

Write your documentation in Markdown, optionally using [Pandoc extensions](https://pandoc.org/MANUAL.html). This
will render nicely on github/gitlab. Use relative links to link between pages: these will be fixed by the generator.

Add a manual target by doing something like:

```cmake
add_manual(speclib
    INSTALL_DESTINATION docs/${PROJECT_NAME}
    MANUAL_SRC ${CMAKE_CURRENT_LIST_DIR}/docs
)
```

This will cause the Markdown documentation tree under `./docs` to be converted to HTML and transplanted to the install
tree at `./docs/${PROJECT_NAME}`. Links between markdown files will be fixed, and any referenced images will also be
copied over.

It is possible to include pages generated by scripts or executables using the `add_manual_generator()` function.

## Trademark Sanitiser

Occasionally, your legal team might pedantically insist that you correctly use the trademark symbol in documentation
and headers. To do so, provide a line such as this in your cmake configuration:

```cmake
set(XCMAKE_SANITISE_TRADEMARKS
    " NVIDIA®"
    "NVIDIA GeForce®"
    "NVIDIA Intellisample™"
    "NVIDIA MediaQore™"
    "NVIDIA nTune™"
    "NVIDIA Quadro®"
    "NVIDIA SLI™"
    "NVIDIA TwinBank®"
CACHE STRING "" FORCE)
```

The format of each line is `<owner> <trademark><symbol>`. The sanitiser will ensure that all generated documentation and
headers installed by the header-target mechanism refer to the trademark exactly in that format the first time it occurs
in a document. Violations are reported as build errors in release mode.

Obviously, making sure your distributed files satisfy your legal team is entirely your own problem ;).

## Simplified Symbol Visibility Management

It is good practice for the default symbol visibility in your binaries to be hidden, with only exposed APIs visible.
Enabling this - especially on Windows - is a tremendous pain. XCMake provides a platform-agnostic mechanism you can use
to achieve this with very little effort. Doing so can yield significant improvements in binary size and build time,
especially for template-heavy code.

Add a line such as:
```cmake
add_export_header(specregex BASE_NAME "SPECREGEX" EXPORT_FILE_NAME "spec/regex/export.h")
```

Where `specregex` is a library target. This will generate an install a header file at `./include/spec/regex/export.h`,
and configure your target such that the file can be included from translation units as `#include <spec/regex/export.h>`.

The generated header will provide a macro named `<BASE_NAME>_EXPORT`, which you should attach to all public APIS in your
binary to render the symbol visible:

```c++
SPECLIB_EXPORT RejectedSpecialisationException::~RejectedSpecialisationException() = default;
```

## [Uniform Package Export](./scripts/Export.cmake)

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

It's unclear why you'd ever want these things to differ, so this simplification is rather handy.
This essentially skips the usual ritual of `configure_package_config_file`, `install(EXPORT)`, `export(EXPORT)`, etc.

## [Automatic external project binding](./scripts/ExternalProj.cmake)

`add_external_project` is a wrapper around [`ExternalProject_Add`](https://cmake.org/cmake/help/latest/module/ExternalProject.html)
that provides `IMPORTED` target generation. The following extra options are provided:
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

`message()` is overridden in a backwards-compatible way, allowing you to optionally specify a colour and/or
log-level in the first two arguments. There are also convenient functions such as `warning()`, `error()` for printing
at certain log-levels, each of which takes an optional colour as the first argument, and uses a nice default otherwise
(except for `warning()`, which takes an `On`/`Off` backtrace argument instead).

```cmake
# These two are equivalent.
message(BLUE "Hello, world")
message(STATUS BLUE "Hello, world")

# These foour are equivalent.
message(FATAL_ERROR "Hello, world")
message(FATAL_ERROR BOLD_RED "Hello, world")
fatal_error("Hello, world")
fatal_error(BOLD_RED "Hello, world")
```

## Dynamic Binding

A mechanism for calling a function by computed name.

```cmake
function(foo)
    # Something interesting
endfunction()

function(bar)
    # Something interesting
endfunction()


set(MY_VAR foo)
dynamic_call(${MY_VAR} some_arg) # Calls `foo(some_arg)`.
```

This is almost suicidally insane, but is occasionally helpful. This feature is not particularly performant, so excessive
use will slow down the execution of `cmake`.

## Exit functions

Run a function after cmake has finished executing (perhaps to generate some kind of report). By default, xcmake uses
this feature to perform a few sanity checks and print a colour-ASCII-art representation of your build system.

```cmake
function (ExampleFunction)
    message(KITTENS)
endfunction()

# Causes `ExampleFunction()` to run after all other cmake execution (except other exit functions) are run.
add_exit_function(ExampleFunction)
```

Exit functions are executed in the order that they are registered.

Although exit functions run after all other cmake execution, they are still run before buildsystem generation. They do
*not* provide a mechanism for you to read the "final value" of generator expressions.

## Scoped Subdirectories

A mechanism for doing `add_subdirectory` while setting certain variables to new values for that subdirectory and
restoring them afterwards.

This is useful for two reasons:
- You need you subdirectory that requires a variable to be a different value.
- You can cope with a subdirectory that randomly changes a global variable in a way that would otherwise break your
  build system.

If you want stronger sandboxing, you probably want to use the external project mechanism instead.

##### Example

```cmake
add_subdirectory_with(somedir -DBUILD_SHARED_LIBS=ON)
```

## Shell-script targets

`add_shell_script()` allows you to add a shell-script as an auto-installed target.

The build step of a shell script target runs `shellcheck` to validate the script.
