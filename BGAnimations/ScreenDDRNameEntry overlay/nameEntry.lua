local player = ...
local NameEntry = LoadModule('NameEntry.lua')

setenv('keysetSDDRN' .. ToEnumShortString(player), 0)

-- local DefaultName = 'STARLGHT'
local DefaultName = 'ANONYMOUS'
local height = 620

return Def.ActorFrame{
	Def.ActorFrame{
		Name='Panes',
		Def.ActorFrame{
			Name='Background',
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
				InitCommand=function(self)
					self:zoomy(height/586)
				end
			},
			Def.Quad{
				Name='BackgroundInner',
				InitCommand=function(self)
					self:setsize(512, height):y(0):diffuse(Alpha(Color.Black, 0.8))
				end,
			},
		},
		Def.ActorFrame{
			InitCommand=function(self)
				self:y(-height/2+2)
			end,
			OnCommand=function(self)
				self:y(0):sleep(0.3):linear(0.3):y(-height/2+2)
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
				self:y(0):sleep(0.3):linear(0.3):y(height/2-5)
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
		DefaultName=DefaultName,
		-- ShowRecentNames=false,
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
		BeginCommand=function(self)
			local top, bottom = self:CalculateTopAndBottom()
			self:y(-(top + bottom)/2)
			
			local bg = self:GetParent():GetChild('Panes'):GetChild('Background'):GetChild('BackgroundInner')
			bg:setsize(bg:GetWidth(), math.min(height, bottom - top + 50))
		end,
		OnCommand=function(self)
			self:hibernate(0.6)
		end,
		OffCommand=function(self)
			self:diffusealpha(0)
		end,
		Def.BitmapText{
			Font='_avenirnext lt pro bold/36px',
			Text='Register a DANCER NAME.\nEnter the name you want to use.',
			InitCommand=function(self)
        self:xy(-250, -225):halign(0):zoom(0.9):strokecolor(Color.Black)
			end,
		},
		Def.BitmapText{
			Font='_avenirnext lt pro bold/25px',
			Text='(Enter blank name to default to ' .. DefaultName .. ')',
			InitCommand=function(self)
				self:xy(-247, -170):zoom(0.8)
				self:halign(0):strokecolor(Color.Black):skewx(-0.15)
			end,
		},
	}
}