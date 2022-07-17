include_guard(GLOBAL)

define_xcmake_target_property(
    SANITISER
    BRIEF_DOCS "The clang-sanitiser to use"
    FULL_DOCS "Enable a clang sanitiser. Valid values are: Address, Leak, Memory, Thread, Undefined"
    VALID_VALUES OFF Address Leak Memory Thread Undefined
    DEFAULT OFF
)
add_library(common_SANITISER_EFFECTS INTERFACE)
add_library(OFF_SANITISER_EFFECTS INTERFACE)  # Nothing.
add_library(Address_SANITISER_EFFECTS INTERFACE)
add_library(Leak_SANITISER_EFFECTS INTERFACE)
add_library(Memory_SANITISER_EFFECTS INTERFACE)
add_library(Thread_SANITISER_EFFECTS INTERFACE)
add_library(Undefined_SANITISER_EFFECTS INTERFACE)

# Common stuff for all sanitisers.
target_compile_options(common_SANITISER_EFFECTS INTERFACE
    # Stuff to make sanitiser output sort of vaguely useful.
    -gcolumn-info
    -fno-omit-frame-pointer
    -fno-optimize-sibling-calls
)

# Sanitiser-specific flags
target_compile_options(Address_SANITISER_EFFECTS INTERFACE
    -fsanitize=address
    -fsanitize-address-use-after-scope
)
target_link_options(Address_SANITISER_EFFECTS INTERFACE -fsanitize=address)

target_compile_options(Leak_SANITISER_EFFECTS INTERFACE -fsanitize=leak)
target_link_options(Leak_SANITISER_EFFECTS INTERFACE -fsanitize=leak)

target_compile_options(Memory_SANITISER_EFFECTS INTERFACE
    -fsanitize=memory
    -fsanitize-memory-track-origins=2
)
target_link_options(Memory_SANITISER_EFFECTS INTERFACE
    -fsanitize=memory
    -fsanitize-memory-track-origins=2
)

target_compile_options(Thread_SANITISER_EFFECTS INTERFACE -fsanitize=thread)
target_link_options(Thread_SANITISER_EFFECTS INTERFACE -fsanitize=thread)

target_compile_options(Undefined_SANITISER_EFFECTS INTERFACE
    -fsanitize=undefined
    -fno-sanitize-recover=undefined
    -fsanitize=unsigned-integer-overflow
)
target_link_options(Undefined_SANITISER_EFFECTS INTERFACE
    -fsanitize=undefined
    -fno-sanitize-recover=undefined
    -fsanitize=unsigned-integer-overflow
)

target_link_libraries(Address_SANITISER_EFFECTS INTERFACE common_SANITISER_EFFECTS)
target_link_libraries(Leak_SANITISER_EFFECTS INTERFACE common_SANITISER_EFFECTS)
target_link_libraries(Memory_SANITISER_EFFECTS INTERFACE common_SANITISER_EFFECTS)
target_link_libraries(Thread_SANITISER_EFFECTS INTERFACE common_SANITISER_EFFECTS)
target_link_libraries(Undefined_SANITISER_EFFECTS INTERFACE common_SANITISER_EFFECTS)

# Configurable sanitizer flags.
if (XCMAKE_SANITIZER_RECOVERY)
    target_compile_options(common_SANITISER_EFFECTS INTERFACE -fsanitize-recover=all)
    target_link_options(common_SANITISER_EFFECTS INTERFACE -fsanitize-recover=all)
endif()
