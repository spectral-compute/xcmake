include_guard(GLOBAL)

default_value(XCMAKE_OPT_LEVEL_Debug none)
default_value(XCMAKE_OPT_LEVEL_Release unsafe)
default_value(XCMAKE_OPT_LEVEL_RelWithDebInfo unsafe)

define_xcmake_target_property(
    OPT_LEVEL
    BRIEF_DOCS "Optimisation level to use"
    FULL_DOCS "Valid values are: none, debug, size, safe, and unsafe. Does more than just setting -Ofoo!"
    DEFAULT ${XCMAKE_OPT_LEVEL_${CMAKE_BUILD_TYPE}}
    VALID_VALUES none debug size safe unsafe
)

# This one has to be funtion-style so we can run a generator expression on TARGET.
function(OPT_LEVEL_EFFECTS TARGET)
    add_library(${TARGET}_none_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_debug_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_safe_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_size_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE)

    target_compile_options(${TARGET}_none_OPT_LEVEL_EFFECTS INTERFACE
            $<$<COMPILE_LANG_AND_ID:CUDA,NVIDIA>:-O0>                   # NVCC
            $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/Od>                      # MSVC
            $<$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang>:-O0>          # Clang
    )
    target_optional_compile_options(${TARGET}_none_OPT_LEVEL_EFFECTS INTERFACE
        -Wno-pass-failed  # Don't complain that loops didn't unroll and so on just because the pass is not enabled.
    )

    target_compile_options(${TARGET}_size_OPT_LEVEL_EFFECTS INTERFACE
        $<$<COMPILE_LANG_AND_ID:CUDA,NVIDIA>:-O2>                   # NVCC
        $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/O1>                      # O1 is "optimise for size" on MSVC...
        $<$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang>:-Oz>          # Clang
        # Can probably do more here if you care enough to bother...
    )

    target_compile_options(${TARGET}_debug_OPT_LEVEL_EFFECTS INTERFACE
        $<$<COMPILE_LANG_AND_ID:CUDA,NVIDIA>:-O0>                   # NVCC
        $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/Od>                      # MSVC
        $<$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang>:-Og>          # Clang
    )

    target_optional_compile_options(${TARGET}_debug_OPT_LEVEL_EFFECTS INTERFACE
        -Wno-pass-failed  # Don't complain that loops didn't unroll and so on just because the pass is not enabled.
    )

    target_compile_options(${TARGET}_safe_OPT_LEVEL_EFFECTS INTERFACE
        $<$<COMPILE_LANG_AND_ID:CUDA,NVIDIA>:-O2>                   # NVCC
        $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/O2>                      # MSVC
        $<$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang>:-O3>          # Clang
    )

    target_compile_options(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE
        # NVCC does nothing, since O2 is the default, and it doesn't accept it twice!
        $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/O2>                      # MSVC
        $<$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang>:-Ofast>       # Clang
    )

    # In optimising builds, have the linker delete unused sections.
    # Note that this *does* do something even without `-ffunction-sections` (and you definitely do not
    # want `-ffunction-sections`, since it hurts performance and LTO does a much better job anyway.
    target_link_options(${TARGET}_safe_OPT_LEVEL_EFFECTS INTERFACE "LINKER:--gc-sections")
    target_link_options(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE "LINKER:--gc-sections")

    # There are also CUDA translation unit specific flags, predicated on the
    # OPT_LEVEL target property, defined in CUDA.cmake

    # CMake unhelpfully adds inline configuration flags that differ between Release and
    # RelWithDebInfo, so we take back control here.
    if (MSVC)
        target_compile_options(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE
            $<$<COMPILE_LANGUAGE:CXX>:/Ob2>  # ... But only do this when compiling C++, not CUDA.
        )
    else()
        target_compile_options(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE
            $<$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang>:-finline-functions>
        )
    endif()

    target_optional_compile_options(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE
        # An experimental but years-old optimisation.
        -fstrict-vtable-pointers
    )

    # I realise this is ridiculous.
    target_link_libraries(
        ${TARGET} PRIVATE
        $<$<BOOL:$<TARGET_PROPERTY:${TARGET},OPT_LEVEL>>:${TARGET}_$<TARGET_PROPERTY:${TARGET},OPT_LEVEL>_OPT_LEVEL_EFFECTS>
    )
endfunction()
