cmake_minimum_required(VERSION 3.29)
project(luajit LANGUAGES C ASM)

option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Output directories
foreach(OUTPUT_CONFIG ARCHIVE LIBRARY RUNTIME)
    set(CMAKE_${OUTPUT_CONFIG}_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
endforeach()
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# ------------------------------
# Lua Source Configuration
# ------------------------------
file(GLOB LUA_SOURCES CONFIGURE_DEPENDS
    "src/*.c"
    "src/*.h"
)

# Exclude interpreter/compiler for lib
list(FILTER LUA_SOURCES EXCLUDE REGEX ".*lua\\.c$")
list(FILTER LUA_SOURCES EXCLUDE REGEX ".*luac\\.c$")

add_library(lua ${LUA_SOURCES})
target_include_directories(lua PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)

# ------------------------------
# Version-Specific Additions
# ------------------------------
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


# ------------------------------
# Executables
# ------------------------------
add_executable(lua_bin src/lua.c)
target_link_libraries(lua_bin PRIVATE lua)
set_target_properties(lua_bin PROPERTIES OUTPUT_NAME "lua")

add_executable(luac_bin src/luac.c)
target_link_libraries(luac_bin PRIVATE lua)
set_target_properties(luac_bin PROPERTIES OUTPUT_NAME "luac")

# ------------------------------
# Installation Rules
# ------------------------------
include(GNUInstallDirs)

install(TARGETS lua lua_bin luac_bin
    EXPORT LuaTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(EXPORT LuaTargets
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/Lua
    NAMESPACE Lua::
)

install(FILES
    src/lua.h
    src/luaconf.h
    src/lauxlib.h
    src/lualib.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

