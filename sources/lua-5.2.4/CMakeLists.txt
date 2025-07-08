# ==============================================================
# Enhanced Lua CMake Build Template (CMake 3.29+)
# ==============================================================

cmake_minimum_required(VERSION 3.29)
project(lua VERSION 5.2.4 LANGUAGES C)

# =====================
# 1. Core Configuration
# =====================
set(LUA_ENGINE "lua" CACHE STRING "Lua engine type")
option(BUILD_SHARED_LIBS "Build shared library" OFF)
option(BUILD_STANDALONE "Build standalone interpreter" ON)

# Always compile with position-independent code
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ===================
# 2. Source Discovery
# ===================
file(GLOB_RECURSE LUA_CORE_SOURCES CONFIGURE_DEPENDS
    "src/*.c"
    "src/*.h"
)

# ===================
# 3. Library Targets
# ===================
add_library(lua STATIC)
target_sources(lua PRIVATE ${LUA_CORE_SOURCES})
target_include_directories(lua PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)

# ================================
# 4. Version-Specific Adjustments
# ================================
# ===================================================
# 🔧 Lua 5.2 Specific Configuration
# ===================================================

# -------------------------------
# 1. Compatibility Definitions
# -------------------------------
target_compile_definitions(lua PRIVATE
    LUA_COMPAT_ALL      # Enable legacy features for 5.2
    LUA_USE_BITLIB
    LUA_USE_BASELIB
    LUA_USE_PACKLIB
)

# -------------------------------
# 2. Version & ABI Properties
# -------------------------------
set_target_properties(lua PROPERTIES
    VERSION "5.2.4"
    SOVERSION "5.2"
)

# -------------------------------
# 3. Platform-Specific Defines
# -------------------------------
if(WIN32)
    target_compile_definitions(lua PRIVATE LUA_USE_WINDOWS_CONSOLE)
else()
    target_compile_definitions(lua PRIVATE LUA_USE_POSIX)
endif()

# -------------------------------
# 4. Compiler Optimization Flags
# -------------------------------
target_compile_options(lua PRIVATE
    $<$<C_COMPILER_ID:GNU,Clang>:
        -O2
        -fno-strict-aliasing
        -fstack-protector-strong
    >
    $<$<C_COMPILER_ID:MSVC>:
        /O2
        /wd4996
    >
)

# -------------------------------
# 5. Language Standard
# -------------------------------
set_target_properties(lua PROPERTIES
    C_STANDARD 99
    C_STANDARD_REQUIRED YES
    C_EXTENSIONS ON
)


# ========================
# 5. Executable Target
# ========================
if(BUILD_STANDALONE)
    add_executable(lua_exe "src/lua.c")
    target_link_libraries(lua_exe PRIVATE lua)
    set_target_properties(lua_exe PROPERTIES OUTPUT_NAME "lua")
endif()

# ======================
# 6. Installation Setup
# ======================
include(GNUInstallDirs)

install(TARGETS lua
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if(BUILD_STANDALONE)
    install(TARGETS lua_exe
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
endif()

install(FILES
    src/lua.h
    src/luaconf.h
    src/lauxlib.h
    src/lualib.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# =========================
# 7. Platform-Specific Fixes
# =========================
if(WIN32)
    if(BUILD_SHARED_LIBS)
        target_compile_definitions(lua PRIVATE LUA_BUILD_AS_DLL)
    endif()
    target_link_options(lua PRIVATE "/STACK:4194304")
else()
    target_link_options(lua PRIVATE
        "LINKER:--stack-size=4194304"
    )
    target_link_libraries(lua PRIVATE m)
endif()

# ===========================
# 8. Modern CMake Enhancements
# ===========================
# Export compile_commands.json for tooling support
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Security hardening flags for UNIX-like systems
if(NOT WIN32)
    target_compile_options(lua PRIVATE
        -D_FORTIFY_SOURCE=2
    )
    target_link_options(lua PRIVATE
        "LINKER:-z,relro"
        "LINKER:-z,now"
    )
endif()

