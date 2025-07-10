# =============================
# LUAJIT 2.1 Configuration
# =============================

include_directories(src)
add_definitions(-DLUAJIT_ENABLE_LUA52COMPAT)

add_custom_target(luajit_build ALL
    COMMAND  -E echo "➡ Building LuaJIT"
    COMMAND  -E chdir src  BUILDMODE=static
    WORKING_DIRECTORY 
)

add_custom_target(install-luajit
    COMMAND  -E echo "📦 Installing LuaJIT to: "
    COMMAND  -E copy src/luajit.exe /luajit.exe
    COMMAND  -E copy src/lua51.dll /lua51.dll
    COMMAND  -E copy src/libluajit.a /libluajit.a
    DEPENDS luajit_build
)
'@
            } else {
                 = @"
# =============================
# LUAJIT 2.1.0-beta3 Configuration
# =============================

# Add any luajit-specific build settings here
