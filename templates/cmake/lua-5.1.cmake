# ===================================================
# Lua 5.1 Specific Configuration
# ===================================================

# ------------------------------
# Core and Compatibility Features
# ------------------------------
target_compile_definitions(lua PRIVATE
    LUA_COMPAT_ALL
    LUA_USE_BASELIB
    LUA_USE_PACKLIB
    LUA_USE_STRLIB
    LUA_USE_MATHLIB
    LUA_USE_IOLIB
    LUA_USE_OSLIB
    LUA_USE_DBLIB
    LUA_USE_TABLIB
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
    $<$<C_COMPILER_ID:GNU,Clang>:-O2 -fno-strict-aliasing>
    $<$<C_COMPILER_ID:MSVC>:/O2 /wd4996>
)

# ------------------------------
# Target Properties
# ------------------------------
set_target_properties(lua PROPERTIES
    VERSION "@LUA_VERSION@"
    SOVERSION "5.1"
    OUTPUT_NAME "lua-5.1"
    C_STANDARD 99
    C_EXTENSIONS ON
)
