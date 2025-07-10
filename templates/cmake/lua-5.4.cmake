# ===================================================
# Lua 5.4 Specific Configuration
# ===================================================

# ------------------------------
# Compatibility and Feature Flags
# ------------------------------
target_compile_definitions(lua PRIVATE
    LUA_COMPAT_5_3
    LUA_USE_APICHECK
    LUA_USE_TOBE_CLOSED
)

# ------------------------------
# Optional GC64 Mode
# ------------------------------
option(LUA_USE_GC64 "Enable GC64 mode" OFF)
if(LUA_USE_GC64)
    target_compile_definitions(lua PRIVATE LUA_USE_GC64)
endif()

# ------------------------------
# Platform-Specific Settings
# ------------------------------
if(WIN32)
    target_compile_definitions(lua PRIVATE
        LUA_USE_WINDOWS_ANSI
        LUA_USE_WINDOWS_UTF8
    )
else()
    target_compile_definitions(lua PRIVATE LUA_USE_POSIX)
endif()

# ------------------------------
# Compiler Optimization Flags
# ------------------------------
target_compile_options(lua PRIVATE
    $<$<C_COMPILER_ID:GNU,Clang>:-O3>
    $<$<C_COMPILER_ID:MSVC>:/O2 /wd4996>
)

# ------------------------------
# Target Properties
# ------------------------------
set_target_properties(lua PROPERTIES
    VERSION "@LUA_VERSION@"
    SOVERSION "5.4"
    OUTPUT_NAME "lua-5.4"
    C_STANDARD 99
    C_EXTENSIONS ON
)
