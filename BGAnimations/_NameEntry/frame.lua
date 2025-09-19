local opts = ...
local pn = opts.Player
local NameEntry = LoadModule('NameEntry.lua')

-- We probably shouldn't amend opts with default values, but cba to clone it
if not opts.DefaultName then
  opts.DefaultName = 'STARLGHT'
end
if not opts.Text then
	opts.Text = 'Enter the DANCER NAME to be\nshown when saving your score.'
end

local tweenTime = 0.1
local height = 620

return Def.ActorFrame{
	Def.Actor{
		HideCommand=function(self)
			-- Let upstream use HideTweenDoneCommand to hook when the Hide tweening 
			-- is done because only we know when it's actually done here.
			self:GetParent():sleep(tweenTime):queuecommand('HideTweenDone')
		end,
	},
	Def.ActorFrame{
		Name='Background',
		InitCommand=function(self)
			self:shadowlength(0)
		end,
		ShowCommand=function(self)
			self:zoomy(0):linear(tweenTime):zoomy(1):diffusealpha(1)
		end,
		HideCommand=function(self)
			self:linear(tweenTime):zoomy(0):diffusealpha(0)
		end,
		Def.Quad{
			InitCommand=function(self)
				-- Same size as ScreenSelectProfile/BG01.png
				self:setsize(532, 586):diffuse(Alpha(Color.White, 0.75))
				self:zoomy(height/586)
			end,
		},
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
			self:shadowlength(0)
		end,
		ShowCommand=function(self)
			self:y(0):linear(tweenTime):y(-height/2+2):diffusealpha(1)
		end,
		HideCommand=function(self)
			self:linear(tweenTime):y(0):diffusealpha(0)
		end,
		Def.Sprite{
			Texture=THEME:GetPathG('', 'ScreenSelectProfile/BGTOP_' .. ToEnumShortString(pn)),
			InitCommand=function(self)
				self:valign(1)
			end,
		},
	},
	Def.ActorFrame{
		InitCommand=function(self)
			self:shadowlength(0)
		end,
		ShowCommand=function(self)
			self:y(0):linear(tweenTime):y(height/2-2):diffusealpha(1)
		end,
		HideCommand=function(self)
			self:linear(tweenTime):y(0):diffusealpha(0)
		end,
		Def.Sprite{
			Texture=THEME:GetPathG('', 'ScreenSelectProfile/BGTOP_' .. ToEnumShortString(pn)),
			InitCommand=function(self)
				self:valign(1):rotationz(180)
			end,
		},
	},
  Def.ActorFrame{
    ShowCommand=function(self)
			local Text = self:GetChild('Text')
			local NameEntry = self:GetChild('NameEntry')
			local top, bottom = NameEntry:CalculateTopAndBottom()
			top = math.min(top, Text:GetY() - Text:GetHeight() / 2) 
			self:y(-(top + bottom)/2)
			
			local bg = self:GetParent():GetChild('Background'):GetChild('BackgroundInner')
			bg:setsize(bg:GetWidth(), math.min(height, bottom - top + 50))
			
      self:hibernate(tweenTime):diffusealpha(1)
    end,
    HideCommand=function(self)
      self:diffusealpha(0)
    end,
    NameEntry(opts) .. {
			Name='NameEntry',
		},
		Def.BitmapText{
			Name='Text',
			Font='_avenirnext lt pro bold/36px',
			Text=opts.Text,
			InitCommand=function(self)
				self:xy(-250, -225):halign(0):zoom(0.9):strokecolor(Color.Black)
			end,
		},
		Def.BitmapText{
			Font='_avenirnext lt pro bold/25px',
			Text='(Enter blank name to default to ' .. opts.DefaultName .. ')',
			InitCommand=function(self)
				self:xy(-247, -170):zoom(0.8)
				self:halign(0):strokecolor(Color.Black):skewx(-0.15)
			end,
		},
	},
}