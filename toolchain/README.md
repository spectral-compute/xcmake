# XCMake Toolchain File
This is XCMake's cross compilation framework. If your project uses XCMake, it will automatically use this toolchain
file. Otherwise, pass `-DCMAKE_TOOLCHAIN_FILE=xcmake/toolchain/toolchain.cmake` to enable it. During cross compilation,
the target tribble to use should be specified using `-DXCMAKE_TRIBBLE=os-arch-microarch`.

## Target Tribbles
XCMake targets are specified using target tribbles. A target tribble is of the form: `os-arch-microarch`.
The components are as follows:

 Component   | Examples                      | Description
-------------|-------------------------------|-------------
 `os`        | `ubuntu16.04`, `win64`        | The operating system for the target.
 `arch`      | `aarch64`, `x86_64`           | The general architecture for the target.
 `microarch` | `avx`, `cortexa57`, `haswell` | The specific microarchitecture. Pseudo microarchitectures, such as `avx` are also permitted.

A target tribble will usually map to a single conventional target triple, but the reverse is not true: many target
tribbles may map to a single target triple. The special target tribble, `native` may be used to specify a native build.

> Target tribbles are like target triples, but soft and furry. They're nicer to work with.

## XCMake Toolchain Options
The XCMake toolchain file uses the following options to control its behaviour:

 Option                      | Description
-----------------------------|-------------
 `XCMAKE_SHOW_TRIBBLE`       | Show the values of the variables set by the toolchain file (including ones set elsewhere and ones left empty). The form is `VARIABLE=VALUE`. This is intended to be used with `cmake -P`.
 `XCMAKE_TOOLCHAIN_BASE_DIR` | Search for toolchains in this directory. Toolchains are searched for by tribble.
 `XCMAKE_TOOLCHAIN_DIR`      | For cross compilation, the directory to find the toolchain in. This is automatically detected by default.
 `XCMAKE_TRIBBLE`            | Specify the target tribble to compile for. The default value is `native`.
 `XCMAKE_TRIPLE_VENDOR`      | Override the default selection of conventional target triple vendor. E.g: `pc` in `x86_64-pc-linux-gnu` or `unknown` in `aarch64-unknown-linux-gnu`.

## XCMake Toolchain Variables
The XCMake toolchain file acts much like any other
[CMake toolchain file](https://cmake.org/Wiki/CMake_Cross_Compiling#The_toolchain_file). In addition to the normal CMake
cross compilation variables, XCMake sets the following variables (if not already set and it not intended to be empty):

 Variable                     | Description
------------------------------|-------------
 `XCMAKE_ARCH`                | The `arch` component from the target tribble.
 `XCMAKE_CTNG_SAMPLE`         | The [crosstool-NG](http://crosstool-ng.github.io/) sample that should be used as a basis for generating a toolchain for this target.
 `XCMAKE_COMPILER_FLAGS`      | The flags that should be prepended to any compiler call.
 `XCMAKE_CONVENTIONAL_TRIPLE` | The conventional target [triplet](http://wiki.osdev.org/Target_Triplet)/[triple](https://clang.llvm.org/docs/CrossCompilation.html) for the target.
 `XCMAKE_GENERIC_TRIBBLE`     | The generic tuplish: binaries from this tribble that are compatible, but less optimized. 
 `XCMAKE_MICROARCH`           | The `microarch` component from the target tribble.
 `XCMAKE_OS`                  | The `os` component from the target tribble.
 `XCMAKE_INTEGRATED_GPU`      | True iff the target's GPU shares the same memory as the CPU (such as a tx2).

## Fragments
Fragments provide information to XCMake's toolchain file in the form of variables. These variables are not intended to
be used outside the toolchain system.

For cross compilation, the order in which the fragments are included is:
1. `toolchain/fragments/arch/${arch}/${microarch}.cmake`
2. `toolchain/fragments/arch/${arch}/common.cmake`
2. `toolchain/fragments/arch/common.cmake`
4. `toolchain/fragments/os/${os}.cmake`
5. `toolchain/fragments/os/common.cmake`
6. `toolchain/fragments/cross.cmake`
7. `toolchain/fragments/common.cmake`

For native compilation, the order in which the fragments are included is:
1. `toolchain/fragments/native.cmake`
2. `toolchain/fragments/common.cmake`
