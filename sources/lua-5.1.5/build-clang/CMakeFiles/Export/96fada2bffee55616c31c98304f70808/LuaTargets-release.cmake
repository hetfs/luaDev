#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "Lua::lua" for configuration "Release"
set_property(TARGET Lua::lua APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(Lua::lua PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/liblua-5.1.a"
  )

list(APPEND _cmake_import_check_targets Lua::lua )
list(APPEND _cmake_import_check_files_for_Lua::lua "${_IMPORT_PREFIX}/lib/liblua-5.1.a" )

# Import target "Lua::lua_bin" for configuration "Release"
set_property(TARGET Lua::lua_bin APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(Lua::lua_bin PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/bin/lua.exe"
  )

list(APPEND _cmake_import_check_targets Lua::lua_bin )
list(APPEND _cmake_import_check_files_for_Lua::lua_bin "${_IMPORT_PREFIX}/bin/lua.exe" )

# Import target "Lua::luac_bin" for configuration "Release"
set_property(TARGET Lua::luac_bin APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(Lua::luac_bin PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/bin/luac.exe"
  )

list(APPEND _cmake_import_check_targets Lua::luac_bin )
list(APPEND _cmake_import_check_files_for_Lua::luac_bin "${_IMPORT_PREFIX}/bin/luac.exe" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
