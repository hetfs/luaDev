# ===================================================
# Lua 5.2 Specific Configuration
# ===================================================

# ------------------------------
# Compatibility and Library Modules
# ------------------------------
target_compile_definitions(lua PRIVATE
    LUA_COMPAT_ALL
    LUA_USE_BITLIB
    LUA_USE_BASELIB
    LUA_USE_PACKLIB
)

# ------------------------------
# Platform-Specific Settings
# ------------------------------
if(WIN32)
    target_compile_definitions(lua PRIVATE LUA_USE_WINDOWS_CONSOLE)
else()
    target_compile_definitions(lua PRIVATE LUA_USE_POSIX)
endif()

# ------------------------------
# Compiler Optimization Flags
# ------------------------------
target_compile_options(lua PRIVATE
    $<$<C_COMPILER_ID:GNU,Clang>:-O2 -fno-strict-aliasing -fstack-protector-strong>
    $<$<C_COMPILER_ID:MSVC>:/O2 /wd4996>
)

# ------------------------------
# Target Properties
# ------------------------------
set_target_properties(lua PROPERTIES
    VERSION "@LUA_VERSION@"
    SOVERSION "5.2"
    OUTPUT_NAME "lua-5.2"
    C_STANDARD 99
    C_EXTENSIONS ON
)
