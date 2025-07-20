cmake_minimum_required(VERSION 3.29)

# ========================================
# Project Setup
# ========================================
# LuaJIT requires numeric-only version in CMake
project(luajit VERSION 2.0.5 LANGUAGES C ASM)

option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ========================================
# Output Directories
# ========================================
foreach(OUTPUT_CONFIG ARCHIVE LIBRARY RUNTIME)
    set(CMAKE_${OUTPUT_CONFIG}_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
endforeach()
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# ========================================
# Optional GC64 Support (LuaJIT 2.1+)
# ========================================


# ========================================
# Source Collection
# ========================================
file(GLOB LUAJIT_SOURCES CONFIGURE_DEPENDS
    "src/*.c"
    "src/*.h"
    "src/*.S"
    "src/*.hpp"
)

# Exclude standalone tools
list(FILTER LUAJIT_SOURCES EXCLUDE REGEX ".*lua\\.c$")
list(FILTER LUAJIT_SOURCES EXCLUDE REGEX ".*luac\\.c$")
list(FILTER LUAJIT_SOURCES EXCLUDE REGEX ".*luajit\\.c$")

# ========================================
# Build Static/Shared Library
# ========================================
add_library(luajit ${LUAJIT_SOURCES})
target_include_directories(luajit PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>
)

# Set version properties
set_target_properties(luajit PROPERTIES
    VERSION "2.0.5"
    SOVERSION "2.0.5"
    OUTPUT_NAME "luajit-2.0.5"
)

# ========================================
# Version-Specific Patches (injected)
# ========================================
# =============================
# LUAJIT 2.0.5 Configuration
# =============================

# Add any luajit-specific build settings here


# ========================================
# luajit Executable
# ========================================
add_executable(luajit_bin src/luajit.c)
target_link_libraries(luajit_bin PRIVATE luajit)
set_target_properties(luajit_bin PROPERTIES OUTPUT_NAME "luajit")

# ========================================
# Installation Rules
# ========================================
include(GNUInstallDirs)

install(TARGETS luajit luajit_bin
    EXPORT LuaJITTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(EXPORT LuaJITTargets
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/LuaJIT
    NAMESPACE LuaJIT::
)

install(FILES
    src/luajit.h
    src/lua.h
    src/luaconf.h
    src/lauxlib.h
    src/lualib.h
    src/lua.hpp
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# ========================================
# Linux Symlinks for Compatibility
# ========================================
if(UNIX AND NOT APPLE)
    install(CODE "
        execute_process(
            COMMAND \${CMAKE_COMMAND} -E create_symlink
            libluajit.so
            \${CMAKE_INSTALL_FULL_LIBDIR}/libluajit.so.\${PROJECT_VERSION_MAJOR}.\${PROJECT_VERSION_MINOR}
        )
    ")
endif()

# ========================================
# macOS RPATH Support (Optional)
# ========================================
if(APPLE)
    set(CMAKE_MACOSX_RPATH ON)
endif()

