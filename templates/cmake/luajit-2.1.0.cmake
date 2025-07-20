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
