# ===================================================
# Lua 5.3 Specific Configuration
# ===================================================

# ------------------------------
# Compatibility and Core Features
# ------------------------------
target_compile_definitions(lua PRIVATE
    LUA_COMPAT_5_2
    LUA_USE_BITWISE_OPERATORS
    LUA_USE_UTF8_LIB
)

# ------------------------------
# Optional 32-bit Integer Mode
# ------------------------------
option(LUA_32BITS "Use 32-bit integers instead of 64-bit" OFF)
if(LUA_32BITS)
    target_compile_definitions(lua PRIVATE LUA_32BITS)
else()
    target_compile_definitions(lua PRIVATE LUA_C89_NUMBERS)
endif()

# ------------------------------
# Platform-Specific Settings
# ------------------------------
if(WIN32)
    target_compile_definitions(lua PRIVATE LUA_USE_WINDOWS_UTF8)
else()
    target_compile_definitions(lua PRIVATE LUA_USE_POSIX)
endif()

# ------------------------------
# Compiler Optimization Flags
# ------------------------------
target_compile_options(lua PRIVATE
    $<$<C_COMPILER_ID:GNU,Clang>:-O2 -fno-strict-aliasing>
    $<$<C_COMPILER_ID:MSVC>:/O2 /wd4996>
)

# ------------------------------
# Target Properties
# ------------------------------
set_target_properties(lua PROPERTIES
    VERSION "@LUA_VERSION@"
    SOVERSION "5.3"
    OUTPUT_NAME "lua-5.3"
    C_STANDARD 99
    C_EXTENSIONS ON
)
