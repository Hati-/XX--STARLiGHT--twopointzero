local t = Def.ActorFrame{};

local SBG = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred")
SBG:StaticBackground(true)
SBG:RandomBGOnly(false)

t[#t+1] = LoadActor("/"..THEME:GetCurrentThemeDirectory().."/BGAnimations/BGScripts/DanceStages.lua");

return t;