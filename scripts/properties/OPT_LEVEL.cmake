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

# This one has to be function-style so we can run a generator expression on TARGET.
function(OPT_LEVEL_EFFECTS TARGET)
    # Bits and pieces to build the optimization levels below.
    set(IS_CLANG $<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang>)
    set(IS_IPO $<BOOL:$<TARGET_PROPERTY:${TARGET},INTERPROCEDURAL_OPTIMIZATION>>)
    set(CLANG_LTO_FLAGS $<$<AND:${IS_CLANG},${IS_IPO}>:-fwhole-program-vtables>)

    # Individual optimization levels.
    add_library(${TARGET}_none_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_debug_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_safe_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_size_OPT_LEVEL_EFFECTS INTERFACE)
    add_library(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE)

    target_compile_options(${TARGET}_none_OPT_LEVEL_EFFECTS INTERFACE
            $<$<COMPILE_LANG_AND_ID:CUDA,NVIDIA>:-O0>                   # NVCC
            $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/Od>                      # MSVC
            $<${IS_CLANG}:-O0>
            ${CLANG_LTO_FLAGS}
    )
    target_optional_compile_options(${TARGET}_none_OPT_LEVEL_EFFECTS INTERFACE
        -Wno-pass-failed  # Don't complain that loops didn't unroll and so on just because the pass is not enabled.
    )

    target_compile_options(${TARGET}_size_OPT_LEVEL_EFFECTS INTERFACE
        $<$<COMPILE_LANG_AND_ID:CUDA,NVIDIA>:-O2>                   # NVCC
        $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/O1>                      # O1 is "optimise for size" on MSVC...
        $<${IS_CLANG}:-Oz>
        ${CLANG_LTO_FLAGS}
        # Can probably do more here if you care enough to bother...
    )

    target_compile_options(${TARGET}_debug_OPT_LEVEL_EFFECTS INTERFACE
        $<$<COMPILE_LANG_AND_ID:CUDA,NVIDIA>:-O0>                   # NVCC
        $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/Od>                      # MSVC
        $<${IS_CLANG}:-Og>
    )
    target_optional_compile_options(${TARGET}_debug_OPT_LEVEL_EFFECTS INTERFACE
        -Wno-pass-failed  # Don't complain that loops didn't unroll and so on just because the pass is not enabled.
    )

    target_compile_options(${TARGET}_safe_OPT_LEVEL_EFFECTS INTERFACE
        $<$<COMPILE_LANG_AND_ID:CUDA,NVIDIA>:-O2>                   # NVCC
        $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/O2 /Ob2>                 # MSVC
        $<${IS_CLANG}:-O3>
        ${CLANG_LTO_FLAGS}
    )
    target_optional_compile_options(${TARGET}_safe_OPT_LEVEL_EFFECTS INTERFACE
        -finline-functions
    )

    target_compile_options(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE
        # NVCC does nothing, since O2 is the default, and it doesn't accept it twice!
        $<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/O2 /Ob2>
        $<${IS_CLANG}:-O3 -ffast-math>
        ${CLANG_LTO_FLAGS}
    )
    target_optional_compile_options(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE
        -fstrict-vtable-pointers # An experimental but years-old optimisation.
        -finline-functions
    )

    # In optimising builds, have the linker delete unused sections.
    # Note that this *does* do something even without `-ffunction-sections` (and you definitely do not
    # want `-ffunction-sections`, since it hurts performance and LTO does a much better job anyway.
    # This causes an error on the macOS build server
    if (NOT APPLE)
        target_link_options(${TARGET}_safe_OPT_LEVEL_EFFECTS INTERFACE "LINKER:--gc-sections")
        target_link_options(${TARGET}_unsafe_OPT_LEVEL_EFFECTS INTERFACE "LINKER:--gc-sections")
    endif()

    # When LTO is enabled, copy the compiler arguments to the linker.
    foreach (LEVEL IN ITEMS none debug size safe unsafe)
        target_link_options(${TARGET}_${LEVEL}_OPT_LEVEL_EFFECTS INTERFACE
                            $<TARGET_PROPERTY:${TARGET}_${LEVEL}_OPT_LEVEL_EFFECTS,INTERFACE_COMPILE_OPTIONS>)
    endforeach()

    # I realise this is ridiculous.
    target_link_libraries(
        ${TARGET} PRIVATE
        $<$<BOOL:$<TARGET_PROPERTY:${TARGET},OPT_LEVEL>>:${TARGET}_$<TARGET_PROPERTY:${TARGET},OPT_LEVEL>_OPT_LEVEL_EFFECTS>
    )
endfunction()
