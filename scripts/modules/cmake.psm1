# cmake.psm1 - Case Sensitivity Fix

function Generate-CMakeLists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][ValidateSet("lua", "luajit")]
        [string]$Engine,

        [Parameter(Mandatory)][string]
        $Version,

        [Parameter(Mandatory)][string]
        $SourcePath,

        [Parameter(Mandatory)][ValidateSet("static", "shared")]
        [string]$BuildType,

        [Parameter(Mandatory)][ValidateSet("msvc", "mingw", "clang")]
        [string]$Compiler,

        [switch]$PreviewOnly
    )

    try {
        $TemplatesDir = Join-Path (Get-TemplatesRoot) "cmake"
        $baseTemplate = Join-Path $TemplatesDir "CMakeLists.$Engine.default.txt"

        if (-not (Test-Path $baseTemplate)) {
            Write-WarningLog "⚠️ Base template missing: $baseTemplate. Creating stub."

            if ($Engine -eq "lua") {
                $defaultBody = @"
cmake_minimum_required(VERSION 3.29)
project($Engine VERSION $Version LANGUAGES C)

# Version-specific settings
@VERSION_SPECIFIC@
"@
            } else {
                $defaultBody = @"
cmake_minimum_required(VERSION 3.29)
project($Engine VERSION $Version LANGUAGES C ASM)

# Library target
add_library(luajit "")

# Executable target
add_executable(luajit_bin src/luajit.c)
target_link_libraries(luajit_bin PRIVATE luajit)

# Include directories (fixed with generator expressions)
target_include_directories(luajit PUBLIC
    `$<BUILD_INTERFACE:`${CMAKE_CURRENT_SOURCE_DIR}/src>
    `$<INSTALL_INTERFACE:include>
)

# Installation rules
install(TARGETS luajit luajit_bin
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(FILES
    src/luajit.h
    src/lua.h
    src/luaconf.h
    src/lauxlib.h
    src/lualib.h
    DESTINATION include
)

# Version-specific configuration
@VERSION_SPECIFIC@
"@
            }

            Set-Content -Path $baseTemplate -Value $defaultBody -Encoding UTF8
        }

        $templateContent = Get-Content $baseTemplate -Raw -Encoding UTF8

        # Extract semantic version
        $semver = if ($Engine -eq 'luajit') {
            if ($Version -match '^(\d+\.\d+\.\d+)') {
                $matches[1]
            } else {
                $Version
            }
        } else {
            $Version
        }

        # Calculate major.minor version
        $majorMinor = if ($semver -match '^(\d+\.\d+)') {
            $matches[1]
        } else {
            $parts = $semver.Split('.')
            if ($parts.Count -ge 2) {
                "$($parts[0]).$($parts[1])"
            } else {
                $semver
            }
        }

        # Replace template variables
        $templateContent = $templateContent `
            -replace "@CMAKE_VERSION@", "3.29" `
            -replace "@LUA_VERSION@", $Version `
            -replace "@LUA_SEMVER@", $semver `
            -replace "@SHARED_FLAG@", ($BuildType -eq 'shared' ? "ON" : "OFF") `
            -replace "@GC64_FLAG@", ($Engine -eq 'luajit' -and $Version -like "2.1*" ? 'option(LUAJIT_ENABLE_GC64 "Enable GC64 mode" OFF)' : "")

        # Determine version-specific snippet
        $verKey = if ($Engine -eq "luajit") {
            "luajit-" + $semver
        } else {
            "lua-" + $Version.Substring(0, 3)
        }

        $verSnippetPath = Join-Path $TemplatesDir "$verKey.cmake"

        # Create version-specific stub if missing or empty
        $createStub = $false
        if (-not (Test-Path $verSnippetPath)) {
            $createStub = $true
        } else {
            $content = Get-Content $verSnippetPath -Raw -Encoding UTF8
            if ([string]::IsNullOrWhiteSpace($content)) {
                $createStub = $true
            }
        }

        if ($createStub) {
            Write-WarningLog "⚠️ Creating version config: $verSnippetPath"

            if ($Engine -eq 'luajit' -and $semver -like '2.1.*') {
                $stubContent = @"
# ===================================================
# LuaJIT 2.1.x Specific Configuration
# ===================================================

# Use GLOB to collect sources (avoids case sensitivity issues)
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

# Add collected sources
target_sources(luajit PRIVATE ${LUAJIT_SOURCES})

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
    VERSION "$semver"
    SOVERSION "$majorMinor"
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
"@
            } else {
                $stubContent = @"
# =============================
# $($Engine.ToUpper()) $Version Configuration
# =============================

# Add any $Engine-specific build settings here
"@
            }

            Set-Content -Path $verSnippetPath -Value $stubContent -Encoding UTF8
        }

        $verContent = Get-Content $verSnippetPath -Raw -Encoding UTF8
        $outputContent = $templateContent -replace '@VERSION_SPECIFIC@', $verContent

        if ($outputContent -match "@VERSION_SPECIFIC@") {
            throw "❌ Version-specific content was not injected properly. Check: $verSnippetPath"
        }

        if ($PreviewOnly) {
            Write-Host "`n📄 Generated CMakeLists.txt preview for $($Engine) $($Version):"
            Write-Host "-----------------------------------------------------"
            Write-Host $outputContent
            Write-Host "-----------------------------------------------------`n"
            return
        }

        $outputPath = Join-Path $SourcePath "CMakeLists.txt"
        Set-Content -Path $outputPath -Value $outputContent -Encoding UTF8

        Write-InfoLog "✅ Generated CMakeLists.txt for $Engine $Version ($BuildType/$Compiler)"
        return $true
    }
    catch {
        Write-ErrorLog "❌ Failed to generate CMakeLists.txt: $($_.Exception.Message)"
        return $false
    }
}
