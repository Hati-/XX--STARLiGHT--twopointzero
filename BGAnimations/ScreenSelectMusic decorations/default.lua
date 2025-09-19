local Deco = Def.ActorFrame{};
if not GAMESTATE:IsCourseMode() then
	Deco[#Deco+1] = loadfile(THEME:GetPathB("ScreenSelectMusic","decorations/Types/"..ThemePrefs.Get("WheelType").."/default.lua"))();
end;

local jk = LoadModule"Jacket.lua"

local op = Def.ActorFrame{};

if THEME:GetMetric("ScreenSelectMusic","UseOptionsList") then
	op[#op+1] = loadfile(THEME:GetPathB("ScreenSelectMusic","decorations/_shared/_OptionsList/default.lua"))();
end

-- NameEntry
local OpenNameEntryFuncs = {}
local NameEntries = Def.ActorFrame{}
for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
	local NameEntry, OpenNameEntry = loadfile(THEME:GetPathB('', '_NameEntry'))(pn)
	local ShowCommand, HideCommand, HideTweenDoneCommand, EnterCommand
	NameEntries[#NameEntries+1] = NameEntry .. {
		InitCommand=function(self)
				local offsetX = IsUsingWideScreen() and 566 or 360
				if pn == PLAYER_1 then
						offsetX = offsetX * -1
				end
				self:xy(_screen.cx + offsetX, _screen.cy)
		end,
		ShowCommand=function(self)
			if ShowCommand then ShowCommand(self) end
		end,
		HideCommand=function(self)
			if HideCommand then HideCommand(self) end
		end,
		HideTweenDoneCommand=function(self)
			if HideTweenDoneCommand then HideTweenDoneCommand(self) end
		end,
		EnterCommand=function(self)
			if EnterCommand then EnterCommand(self) end
		end,
	}
	OpenNameEntryFuncs[pn] = function(opts)
		ShowCommand = opts.ShowCommand
		HideCommand = opts.HideCommand
		HideTweenDoneCommand = opts.HideTweenDoneCommand
		EnterCommand = opts.EnterCommand
		return OpenNameEntry()
	end
end

local function OpenNameEntry(player, ...)
	return OpenNameEntryFuncs[player](...)
end

return Def.ActorFrame{
	Def.Actor{
		BeginCommand=function(self)
			-- Due to how the decoration layer works, children of the returned ActorFrame gets moved to become direct children
			-- of the screen object itself. Because of this, non-child properties such as OnCommand and ctx gets lost. 
			-- InitCommands will still execute, as they're called on Actor creation, but any properties InitCommand sets on
			-- the returned ActorFrame will gets lost. To fix this, we set the properties on the screen object itself (which
			-- is a subclass of ActorFrame), but to get the current screen object we have to wait until BeginCommand. See:
			-- https://github.com/stepmania/stepmania/blob/d55acb1ba26f1c5b5e3048d6d6c0bd116625216f/src/ScreenWithMenuElements.cpp#L89
			-- https://github.com/stepmania/stepmania/blob/d55acb1ba26f1c5b5e3048d6d6c0bd116625216f/src/ScreenManager.cpp#L130
			local screen = SCREENMAN:GetTopScreen()
		
			-- Allow downstream actors to access OpenNameEntry. This (obscure) "ctx" feature works by having every child of an
			-- ActorFrame inherit ctx properties through __index metatables. Screens inherits this ActorFrame behvaior. See:
			-- https://github.com/stepmania/stepmania/blob/d55acb1ba26f1c5b5e3048d6d6c0bd116625216f/src/Actor.cpp#L1568
			screen.ctx.OpenNameEntry = OpenNameEntry
		end,
		OnCommand=function(s) 
			setenv("OPList",0)
		end,
	};
	PlayerJoinedMessageCommand=function(self,param)
		SCREENMAN:GetTopScreen():SetNextScreenName("ScreenSelectMusic"):StartTransitioningScreen("SM_GoToNextScreen")
  	end;
	CodeMessageCommand=function(s,p)
		if p.PlayerNumber == PLAYER_1 then
			if p.Name == "OpenOL" then
				SCREENMAN:GetTopScreen():OpenOptionsList(PLAYER_1)
			end
		end
		if p.PlayerNumber == PLAYER_2 then
			if p.Name == "OpenOL" then
				SCREENMAN:GetTopScreen():OpenOptionsList(PLAYER_2)
			end
		end
	end,
	OffCommand=function(s)
		s:sleep(1):queuecommand("Dim")
	end,
	DimCommand=function(s) SOUND:DimMusic(0,math.huge) end,
	Def.Sound{
		File=THEME:GetPathS("","_swoosh in"),
		OnCommand=function(s) s:play() end,
	},
	Def.Sound{
		Name="MWChange",
		File=THEME:GetPathS("","MusicWheel/dance/Default/change.ogg"),
		IsAction=true,
	};
	Deco;
	loadfile(THEME:GetPathB("ScreenSelectMusic","decorations/InputHandler.lua"))();
	op;
	Def.Sound{
		File=THEME:GetPathS("","_swoosh out"),
		OffCommand=function(s) s:sleep(1):queuecommand("Play") end,
		PlayCommand=function(s) s:play() end,
	};
	Def.Sound{
		File=THEME:GetPathB("ScreenSelectMusic","decorations/_shared/bruh.ogg"),
		OffCommand=function(s)
			local song = GAMESTATE:GetCurrentSong()
			local gettitle = song:GetDisplayMainTitle()
			if gettitle == "BroGamer" then
				if PROFILEMAN:IsPersistentProfile(PLAYER_1) or PROFILEMAN:IsPersistentProfile(PLAYER_2) then
					if PROFILEMAN:GetSongNumTimesPlayed(song, 'ProfileSlot_Player1') >= 10 or PROFILEMAN:GetSongNumTimesPlayed(song, 'ProfileSlot_Player2') >=10 then
						SCREENMAN:SystemMessage("You've played BroGamer "..PROFILEMAN:GetSongNumTimesPlayed(song, 'ProfileSlot_Player1').." times. Please seek help.")
						s:sleep(0.5):queuecommand("Bruh")
					end
				end
			end
		end,
		BruhCommand=function(s)
			s:play()
		end,
	},
	NameEntries,
}