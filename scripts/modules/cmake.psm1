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

            $defaultHeader = @"
cmake_minimum_required(VERSION 3.29)
project($Engine VERSION $Version LANGUAGES C)
"@

            $defaultBody = if ($Engine -eq "lua") {
@"
$defaultHeader
# Version-specific settings
@VERSION_SPECIFIC@
"@
            } else {
@"
$defaultHeader
add_executable(luajit src/luajit.c)
@VERSION_SPECIFIC@
"@
            }

            Set-Content -Path $baseTemplate -Value $defaultBody -Encoding UTF8
        }

        $templateContent = Get-Content $baseTemplate -Raw -Encoding UTF8

        # 🔹 Extract semver if LuaJIT
        $semver = if ($Engine -eq 'luajit') {
            if ($Version -match '^(\d+\.\d+\.\d+)') {
                $matches[1]
            } else {
                $Version
            }
        } else {
            $Version
        }

        # ✅ Replace all template variables
        $templateContent = $templateContent `
            -replace "@CMAKE_VERSION@", "3.29" `
            -replace "@LUA_VERSION@", $Version `
            -replace "@LUA_SEMVER@", $semver `
            -replace "@SHARED_FLAG@", ($BuildType -eq 'shared' ? "ON" : "OFF") `
            -replace "@GC64_FLAG@", ($Engine -eq 'luajit' -and $Version -like "2.1*" ? 'option(LUAJIT_ENABLE_GC64 "Enable GC64 mode" OFF)' : "")

        # 🔹 Version snippet selection
        $verKey = if ($Engine -eq "luajit") {
            "luajit-" + $semver
        } else {
            "lua-" + $Version.Substring(0, 3)
        }

        $verSnippetPath = Join-Path $TemplatesDir "$verKey.cmake"

        $createStub = $false
        $isMissingOrEmpty = -not (Test-Path $verSnippetPath) -or ((Get-Content $verSnippetPath -Raw -Encoding UTF8).Trim().Length -eq 0)

        if ($isMissingOrEmpty) {
            Write-WarningLog "⚠️ Creating version config: $verSnippetPath"

            if ($Engine -eq 'luajit' -and $semver -like '2.1.*') {
                $stubContent = @"
# =============================
# LUAJIT 2.1 Configuration
# =============================

include_directories(src)
add_definitions(-DLUAJIT_ENABLE_LUA52COMPAT)

add_custom_target(luajit_build ALL
    COMMAND ${CMAKE_COMMAND} -E echo "➡ Building LuaJIT"
    COMMAND ${CMAKE_COMMAND} -E chdir src ${MAKE} BUILDMODE=static
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

add_custom_target(install-luajit
    COMMAND ${CMAKE_COMMAND} -E echo "📦 Installing LuaJIT to: ${CMAKE_INSTALL_PREFIX}"
    COMMAND ${CMAKE_COMMAND} -E copy src/luajit.exe ${CMAKE_INSTALL_PREFIX}/luajit.exe
    COMMAND ${CMAKE_COMMAND} -E copy src/lua51.dll ${CMAKE_INSTALL_PREFIX}/lua51.dll
    COMMAND ${CMAKE_COMMAND} -E copy src/libluajit.a ${CMAKE_INSTALL_PREFIX}/libluajit.a
    DEPENDS luajit_build
)
'@
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
