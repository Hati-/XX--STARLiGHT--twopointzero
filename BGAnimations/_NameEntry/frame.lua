local opts = ...
local pn = opts.Player
local NameEntry = LoadModule('NameEntry.lua')

-- We probably shouldn't amend opts with default values, but cba to clone it
if not opts.DefaultName then
  opts.DefaultName = 'STARLGHT'
end
if not opts.Text then
	opts.Text = 'Change the DANCER NAME \nthat\'s used when saving score.'
end

return Def.ActorFrame{
	Def.ActorFrame{
		InitCommand=function(self)
			self:shadowlength(0)
		end,
		ShowCommand=function(self)
			self:zoomy(0):linear(0.1):zoomy(1):diffusealpha(1)
		end,
		HideCommand=function(self)
			self:linear(0.1):zoomy(0):diffusealpha(0)
		end,
		Def.Quad{
			InitCommand=function(self)
				-- Same size as ScreenSelectProfile/BG01.png
				self:setsize(532, 586):diffuse(Alpha(Color.White, 0.75))
			end,
		},
		Def.Sprite{
			Texture=THEME:GetPathG('', 'ScreenSelectProfile/BG01'),
		},
		Def.Quad{
			InitCommand=function(self)
				self:setsize(512, 440):y(-20):diffuse(Alpha(Color.Black, 0.8))
			end,
		},
	},
	Def.ActorFrame{
		InitCommand=function(self)
			self:shadowlength(0)
		end,
		ShowCommand=function(self)
			self:y(0):linear(0.1):y(-291):diffusealpha(1)
		end,
		HideCommand=function(self)
			self:linear(0.1):y(0):diffusealpha(0)
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
			self:y(0):linear(0.1):y(291):diffusealpha(1)
		end,
		HideCommand=function(self)
			self:linear(0.1):y(0):diffusealpha(0)
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
      self:hibernate(0.1):diffusealpha(1)
    end,
    HideCommand=function(self)
      self:diffusealpha(0)
    end,
    NameEntry(opts),
    Def.BitmapText{
      Font='_avenirnext lt pro bold/36px',
      Text=opts.Text,
      InitCommand=function(self)
        self:xy(-250, -190):halign(0):zoom(0.9):strokecolor(Color.Black)
      end,
    },
	}
}