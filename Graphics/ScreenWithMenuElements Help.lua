return Def.ActorFrame{
	Def.ActorFrame{
		InitCommand=function(self)
			self:zoomx(1.15)
		end,
		Def.Sprite{
			Texture='_footer/backer',
		},
		Def.Sprite{
			Texture='_footer/backer',
		},
	},
	Def.HelpDisplay{
		File = THEME:GetPathF('HelpDisplay', 'text'),
		InitCommand=function(self)
			local text = THEME:GetString(Var('LoadingScreen'), 'HelpText')
			self:SetTipsColonSeparated(text)
			self:SetSecsBetweenSwitches(5)
			self:shadowlength(0)
			self:strokecolor(Color.Black)
		end,
		SetHelpTextCommand=function(self, params)
			self:SetTipsColonSeparated(params.Text)
		end,
	},
}