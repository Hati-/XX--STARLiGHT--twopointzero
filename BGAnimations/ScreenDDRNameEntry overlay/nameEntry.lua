local player = ...
local NameEntry = LoadModule('NameEntry.lua')

setenv('keysetSDDRN' .. ToEnumShortString(player), 0)

return NameEntry{
	DefaultName='STARLGHT',
	Player=player,
	AllowKeyboard=(player == PLAYER_1),
	AllowInputCallback=function(self)
		return getenv('SDDRNJoined' .. player) == 1
	end,
	EnterCallback=function(self)
		setenv('keysetSDDRN' .. ToEnumShortString(player), 1)
		if GAMESTATE:GetNumPlayersEnabled() == 1 or (getenv('keysetSDDRNP1') == 1 and getenv('keysetSDDRNP2') == 1) then
			self:sleep(0.5):queuecommand('NextScreen')
		end
	end,
	NextScreenCommand=function()
		SCREENMAN:GetTopScreen():StartTransitioningScreen('SM_GoToNextScreen')
	end,
}