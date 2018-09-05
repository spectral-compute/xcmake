include_guard(GLOBAL)

define_xcmake_target_property(
    SANITISER
    BRIEF_DOCS "The clang-sanitiser to use"
    FULL_DOCS "Use of multiple sanitisers causes problems. Valid values are: Address, Leak, Memory, Thread, Undefined"
)
add_library(common_SANITISER_EFFECTS INTERFACE)
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
target_link_libraries(Address_SANITISER_EFFECTS INTERFACE -fsanitize=address)

target_compile_options(Leak_SANITISER_EFFECTS INTERFACE -fsanitize=leak)
target_link_libraries(Leak_SANITISER_EFFECTS INTERFACE -fsanitize=leak)

target_compile_options(Memory_SANITISER_EFFECTS INTERFACE -fsanitize=memory)
target_link_libraries(Memory_SANITISER_EFFECTS INTERFACE -fsanitize=memory)

target_compile_options(Thread_SANITISER_EFFECTS INTERFACE -fsanitize=thread)
target_link_libraries(Thread_SANITISER_EFFECTS INTERFACE -fsanitize=thread)

target_compile_options(Undefined_SANITISER_EFFECTS INTERFACE
    -fsanitize=undefined
    -fno-sanitize-recover=undefined
    -fsanitize=unsigned-integer-overflow
)
target_link_libraries(Undefined_SANITISER_EFFECTS INTERFACE
    -fsanitize=undefined
    -fno-sanitize-recover=undefined
    -fsanitize=unsigned-integer-overflow
)

target_link_libraries(Address_SANITISER_EFFECTS INTERFACE common_SANITISER_EFFECTS)
target_link_libraries(Leak_SANITISER_EFFECTS INTERFACE common_SANITISER_EFFECTS)
target_link_libraries(Memory_SANITISER_EFFECTS INTERFACE common_SANITISER_EFFECTS)
target_link_libraries(Thread_SANITISER_EFFECTS INTERFACE common_SANITISER_EFFECTS)
target_link_libraries(Undefined_SANITISER_EFFECTS INTERFACE common_SANITISER_EFFECTS)
