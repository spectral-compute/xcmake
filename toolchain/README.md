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
