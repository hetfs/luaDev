# ===========================================================
# CMakeLists.luajit.txt — Modern LuaJIT CMake Build Template
# ===========================================================
cmake_minimum_required(VERSION 3.29)
project(LuaJIT VERSION @LUA_VERSION@ LANGUAGES C ASM)

# =====================
# 1. Global Definitions
# =====================
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
option(BUILD_SHARED_LIBS "Build shared library" @SHARED_FLAG@)
option(LUAJIT_ENABLE_JIT "Enable JIT compiler" ON)
option(LUAJIT_ENABLE_FFI "Enable foreign function interface" ON)
option(LUAJIT_USE_GC64 "Enable GC64 mode" @GC64_FLAG@)

# Platform definition for downstream tools
set(LUA_ENGINE "luajit" CACHE STRING "Engine name")

# =====================
# 2. Source Declaration
# =====================
set(LUAJIT_SOURCES
    src/lj_alloc.c
    src/lj_api.c
    src/lj_arch.c
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
    src/lj_opt_loop.c
    src/lj_opt_mem.c
    src/lj_opt_narrow.c
    src/lj_opt_sink.c
    src/lj_opt_split.c
    src/lj_parse.c
    src/lj_prng.c
    src/lj_profile.c
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
    src/lib_aux.c
    src/lib_base.c
    src/lib_bit.c
    src/lib_debug.c
    src/lib_ffi.c
    src/lib_init.c
    src/lib_io.c
    src/lib_jit.c
    src/lib_math.c
    src/lib_os.c
    src/lib_package.c
    src/lib_string.c
    src/lib_table.c
)

# =====================
# 3. LuaJIT Library
# =====================
add_library(luajit)
target_sources(luajit PRIVATE ${LUAJIT_SOURCES})
target_include_directories(luajit PUBLIC src)

set_target_properties(luajit PROPERTIES
    OUTPUT_NAME "lua51"
    VERSION "@LUA_VERSION@"
    SOVERSION "@LUA_VERSION_MAJOR@.@LUA_VERSION_MINOR@"
)

# =====================
# 4. Compile Definitions
# =====================
target_compile_definitions(luajit PRIVATE
    $<$<BOOL:LUAJIT_ENABLE_JIT>:LUAJIT_ENABLE_JIT>
    $<$<BOOL:LUAJIT_ENABLE_FFI>:LUAJIT_ENABLE_FFI>
    $<$<BOOL:LUAJIT_USE_GC64>:LUAJIT_USE_GC64>
)

# =====================
# 5. Architecture Options
# =====================
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86|x86_64|AMD64")
    target_compile_definitions(luajit PRIVATE LUAJIT_ARCH_x64)
    target_compile_options(luajit PRIVATE
        $<$<C_COMPILER_ID:GNU,Clang>:-msse2>
        $<$<C_COMPILER_ID:MSVC>:/arch:SSE2>
    )
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm|aarch64")
    target_compile_definitions(luajit PRIVATE LUAJIT_ARCH_arm64)
else()
    target_compile_definitions(luajit PRIVATE LUAJIT_ARCH_generic)
endif()

# =====================
# 6. Platform Config
# =====================
if(WIN32)
    if(BUILD_SHARED_LIBS)
        target_compile_definitions(luajit PRIVATE LUA_BUILD_AS_DLL)
    endif()
    target_link_options(luajit PRIVATE "/STACK:4194304")
else()
    target_compile_definitions(luajit PRIVATE
        LUAJIT_USE_POSIX
        LUAJIT_USE_DLOPEN
    )
    target_link_libraries(luajit PRIVATE m)
    target_link_options(luajit PRIVATE "LINKER:--stack-size=4194304")
endif()

# =====================
# 7. Compiler Flags
# =====================
target_compile_options(luajit PRIVATE
    $<$<C_COMPILER_ID:GNU,Clang>:
        -O3
        -fomit-frame-pointer
        -fno-strict-aliasing
        -Wno-maybe-uninitialized
    >
    $<$<C_COMPILER_ID:MSVC>:
        /O2
        /Oy-
        /wd4146
        /wd4293
    >
)

# =====================
# 8. Executable
# =====================
add_executable(luajit_bin src/luajit.c)
target_link_libraries(luajit_bin PRIVATE luajit)
set_target_properties(luajit_bin PROPERTIES OUTPUT_NAME "luajit")

# =====================
# 9. Installation
# =====================
include(GNUInstallDirs)
install(TARGETS luajit luajit_bin
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(FILES
    src/lua.h
    src/luaconf.h
    src/lauxlib.h
    src/lualib.h
    src/luajit.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# =====================
# 10. Optional LTO
# =====================
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set_target_properties(luajit PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)
    target_compile_options(luajit PRIVATE
        $<$<C_COMPILER_ID:GNU,Clang>:-flto>
    )
endif()
