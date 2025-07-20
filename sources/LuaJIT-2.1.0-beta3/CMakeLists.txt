cmake_minimum_required(VERSION 3.29)

# ========================================
# Project Setup
# ========================================
# LuaJIT requires numeric-only version in CMake
project(luajit VERSION 2.1.0 LANGUAGES C ASM)

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
option(LUAJIT_ENABLE_GC64 "Enable GC64 mode" OFF)

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
    VERSION "2.1.0-beta3"
    SOVERSION "2.1.0"
    OUTPUT_NAME "luajit-2.1.0-beta3"
)

# ========================================
# Version-Specific Patches (injected)
# ========================================
# ===================================================
# LuaJIT 2.1.x Specific Configuration
# ===================================================

# Add actual sources (VERIFIED for 2.1.0-beta3)
target_sources(luajit PRIVATE
    src/lj_alloc.c
    src/lib_aux.c
    src/lib_base.c
    src/lib_debug.c
    src/lib_init.c
    src/lib_io.c
    src/lib_jit.c
    src/lib_math.c
    src/lib_os.c
    src/lib_package.c
    src/lib_string.c
    src/lib_table.c
    src/lj_api.c
    src/lj_asm.c
    src/lj_assert.c
    src/lj_bc.c
    src/lj_bcread.c
    src/lj_bcwrite.c
    src/lj_carith.c
    src/lj_ccall.c
    src/lj_ccallback.c
    src/lj_cconv.c
    src/lj_cdata.c
    src/lj_char.c
    src/lj_clib.c
    src/lj_cparse.c
    src/lj_crecord.c
    src/lj_ctype.c
    src/lj_debug.c
    src/lj_dispatch.c
    src/lj_err.c
    src/lj_ffrecord.c
    src/lj_func.c
    src/lj_gc.c
    src/lj_gdbjit.c
    src/lj_ir.c
    src/lj_lex.c
    src/lj_lib.c
    src/lj_load.c
    src/lj_mcode.c
    src/lj_meta.c
    src/lj_obj.c
    src/lj_opt_dce.c
    src/lj_opt_fold.c
    src/lj_opt_loop.c
    src/lj_opt_mem.c
    src/lj_opt_narrow.c
    src/lj_opt_sink.c
    src/lj_opt_split.c
    src/lj_parse.c
    src/lj_record.c
    src/lj_snap.c
    src/lj_state.c
    src/lj_str.c
    src/lj_strscan.c
    src/lj_tab.c
    src/lj_trace.c
    src/lj_udata.c
    src/lj_vmevent.c
    src/lj_vmmath.c
)

# JIT Compilation
target_compile_definitions(luajit PRIVATE LUAJIT_ENABLE_JIT)

# Architecture-Specific Optimizations
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    target_compile_definitions(luajit PRIVATE LUAJIT_ARCH_x64)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
    target_compile_definitions(luajit PRIVATE LUAJIT_ARCH_arm64)
endif()

# Optional FFI Support
option(LUAJIT_ENABLE_FFI "Enable FFI for LuaJIT" ON)
if(LUAJIT_ENABLE_FFI)
    target_compile_definitions(luajit PRIVATE LUAJIT_ENABLE_FFI)
    if(UNIX AND NOT APPLE)
        target_link_libraries(luajit PRIVATE dl)
    endif()
endif()

# Version Metadata
set_target_properties(luajit PROPERTIES
    VERSION "2.1.0"
    SOVERSION "2.1"
    OUTPUT_NAME "luajit"
)

# DLL Export Flags for Windows
if(BUILD_SHARED_LIBS AND WIN32)
    target_compile_definitions(luajit PRIVATE LUA_BUILD_AS_DLL)
endif()

# Linker Options and Math Library
if(WIN32)
    target_link_options(luajit PRIVATE "/STACK:4194304")
else()
    target_link_options(luajit PRIVATE "LINKER:--stack-size=4194304")
    target_link_libraries(luajit PRIVATE m)
endif()


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

