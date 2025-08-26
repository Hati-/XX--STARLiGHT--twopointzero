-- Hack fixes numerous lua scripts that only checks for "Lua 5.3", but not higher versions. ( Looking at you DanceStage loaders )
if IsLuaVersionAtLeast(5, 3) then _VERSION = 'Lua 5.3' end