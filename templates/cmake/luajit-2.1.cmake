# ===================================================
# LuaJIT 2.1.x Specific Configuration
# ===================================================

# ------------------------------
# JIT Compilation
# ------------------------------
target_compile_definitions(luajit PRIVATE LUAJIT_ENABLE_JIT)

# ------------------------------
# Architecture-Specific Optimizations
# ------------------------------
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    target_compile_definitions(luajit PRIVATE LUAJIT_ARCH_x64)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
    target_compile_definitions(luajit PRIVATE LUAJIT_ARCH_arm64)
endif()

# ------------------------------
# Optional FFI Support
# ------------------------------
option(LUAJIT_ENABLE_FFI "Enable FFI for LuaJIT" ON)
if(LUAJIT_ENABLE_FFI)
    target_compile_definitions(luajit PRIVATE LUAJIT_ENABLE_FFI)
    if(UNIX AND NOT APPLE)
        target_link_libraries(luajit PRIVATE dl)
    endif()
endif()

# ------------------------------
# Version Metadata
# ------------------------------
set_target_properties(luajit PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}"
    OUTPUT_NAME "luajit-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}"
)

# ------------------------------
# DLL Export Flags for Windows
# ------------------------------
if(BUILD_SHARED_LIBS AND WIN32)
    target_compile_definitions(luajit PRIVATE LUA_BUILD_AS_DLL)
endif()

# ------------------------------
# Linker Options and Math Library
# ------------------------------
if(WIN32)
    target_link_options(luajit PRIVATE "/STACK:4194304")
else()
    target_link_options(luajit PRIVATE "LINKER:--stack-size=4194304")
    target_link_libraries(luajit PRIVATE m)
endif()
