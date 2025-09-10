local player = ...
local NameEntry = LoadModule('NameEntry.lua')

setenv('keysetSDDRN' .. ToEnumShortString(player), 0)

return Def.ActorFrame{
	Def.ActorFrame{
		Name='Panes',
		Def.ActorFrame{
			InitCommand=function(self)
				self:shadowlength(0):zoomy(0)
			end,
			OnCommand=function(self)
				self:sleep(0.3):linear(0.3):zoomy(1)
			end,
			OffCommand=function(self)
				self:linear(0.1):zoomy(0)
			end,
			Def.Sprite{
				Texture=THEME:GetPathG('', 'ScreenSelectProfile/BG01'),
			},
			Def.Quad{
				InitCommand=function(self)
					self:setsize(512, 440):y(-20):diffuse(Alpha(Color.Black, 0.75))
				end,
			},
		},
		Def.ActorFrame{
			InitCommand=function(self)
				self:y(-292)
			end,
			OnCommand=function(self)
				self:y(0):sleep(0.3):linear(0.3):y(-292)
			end,
			OffCommand=function(self)
				self:linear(0.1):y(0):sleep(0):diffusealpha(0)
			end,
			Def.Sprite{
				Texture=THEME:GetPathG('', 'ScreenSelectProfile/BGTOP_' .. ToEnumShortString(player)),
				InitCommand=function(self)
					self:valign(1)
				end,
			},
		},
		Def.ActorFrame{
			Name='Bottom',
			InitCommand=function(self)
				self:shadowlength(0)
			end,
			OnCommand=function(self)
				self:y(0):sleep(0.3):linear(0.3):y(286)
			end,
			OffCommand=function(self)
				self:linear(0.1):y(0):sleep(0):diffusealpha(0)
			end,
			Def.Sprite{
				Texture=THEME:GetPathG('', 'ScreenSelectProfile/BGBOTTOM'),
				InitCommand=function(s) s:valign(0) end,
			},
			Def.Sprite{
				Texture=THEME:GetPathG('', 'ScreenSelectProfile/start game'),
					InitCommand=function(s) s:valign(0):diffusealpha(0) end,
					OnCommand=function(s) s:sleep(0.8):diffusealpha(1) end,
			},
		},
	},
	NameEntry{
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
		InitCommand=function(self)
			self:hibernate(0.6)
		end,
		OffCommand=function(self)
			self:diffusealpha(0)
		end,
		Def.BitmapText{
			Font='_avenirnext lt pro bold/36px',
			InitCommand=function(self)
				self:xy(-250, -190):halign(0):zoom(0.9):strokecolor(Color.Black)
			end,
			Text='Register a DANCER NAME.\nEnter the name you want to use.',
		},
	}
}