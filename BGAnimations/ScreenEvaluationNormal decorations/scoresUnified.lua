local pn = ...
local ScoreAndGrade = LoadModule('ScoreAndGrade.lua')

local t = Def.ActorFrame{}
-- Holy fcuk yes it's finally working (inefficient as it may be)
local function RivalScore(pn, rival)
	return Def.ActorFrame{
		OnCommand=function(self) self:playcommand('Set') end,
		CurrentSongChangedMessageCommand=function(self) self:playcommand('Set') end,
		CurrentCourseChangedMessageCommand=function(self) self:playcommand('Set') end,
		['CurrentSteps'..ToEnumShortString(pn)..'ChangedMessageCommand']=function(self) self:queuecommand('Set') end,
		['CurrentTrail'..ToEnumShortString(pn)..'ChangedMessageCommand']=function(self) self:queuecommand('Set') end,
		['ProfileDisplayName'..ToEnumShortString(pn)..'ChangedMessageCommand']=function(self) self:queuecommand('Set') end,
		SetCommand=function(self)      
			local c = self:GetChildren()
			
			local SongOrCourse, StepsOrTrail
			if GAMESTATE:IsCourseMode() then
				SongOrCourse = GAMESTATE:GetCurrentCourse()
				StepsOrTrail = GAMESTATE:GetCurrentTrail(pn)
			else
				SongOrCourse = GAMESTATE:GetCurrentSong()
				StepsOrTrail = GAMESTATE:GetCurrentSteps(pn)
			end
			if not (SongOrCourse and StepsOrTrail) then
				c.Score:visible(false)
				c.GradeFrame:visible(false)
				c.ScoreName:visible(false)
				return
			end
			
			local profile
			if PROFILEMAN:IsPersistentProfile(pn) then
				profile = PROFILEMAN:GetProfile(pn)
			else
				profile = PROFILEMAN:GetMachineProfile()
			end
			local scores = profile:GetHighScoreList(SongOrCourse, StepsOrTrail):GetHighScores()
			local score = scores[rival]
			if not score then
				c.Score:visible(false)
				c.GradeFrame:visible(false)
				c.ScoreName:visible(false)
				return
			end
			c.Score:visible(true)
			c.GradeFrame:visible(true)
			c.ScoreName:visible(true)
			
			local name
			local isYou = false
			if score:IsFillInMarker() then
				local scorePlayer = RankingFillInMarkerToPlayerNumber(score:GetName())
				if scorePlayer then
					name = PROFILEMAN:GetProfile(scorePlayer):GetDisplayName()
					if scorePlayer == pn then
						isYou = true
					end
				end
			end
			
			if not name then
				name = score:GetName()
			end
			c.ScoreName:settext(name)
			
			if isYou then
				local nameRightX = c.ScoreName:GetX() + c.ScoreName:GetWidth()
				c.YouIndicator:visible(true)
				c.YouIndicator:halign(0):x(nameRightX + 8)
				c.YouIndicator:glowblink():effectcolor1(color('1,1,1,0')):effectcolor2(color('1,1,1,0.2')):effectperiod(0.2)
			else
				c.YouIndicator:visible(false)
				c.YouIndicator:stopeffect()
			end
			
			self:playcommand('SetScore', { Stats = score, Steps = StepsOrTrail })
		end,
		Def.BitmapText{
			Font='_avenirnext lt pro bold/25px',
			Text=THEME:GetString('ScreenEvaluation','RIVAL' .. rival),
			InitCommand=function(self)
				self:halign(1):x(-130):maxwidth(140):strokecolor(Alpha(Color.Black, 0.4))
			end,
		},
		Def.BitmapText{
			Name='ScoreName',
			Font='_avenirnext lt pro bold/25px',
			InitCommand=function(self)
				self:zoom(1):halign(0):x(-117):strokecolor(Color.Black)
			end,
		},
		Def.BitmapText{
			Name='YouIndicator',
			Font='_avenirnext lt pro bold/16px',
			Text='YOU',
			InitCommand=function(self)
				self:visible(false)
				self:zoom(0.95):valign(0.75):skewx(-0.15)
				self:halign(0.5):x(70)
				self:diffusecolor(color('#ffd800')):strokecolor(Color.Black)
			end,
		},
		ScoreAndGrade.CreateScoreActor{	
			Name='Score',
			Font='_avenirnext lt pro bold/25px',
			InitCommand=function(self)
				self:x(220):zoom(1):halign(1):strokecolor(Color.Black)
			end,
		},
		ScoreAndGrade.CreateGradeActor{
			Name='GradeFrame',
			InitCommand=function(self)
				self:x(247):zoom(1.1)
			end,
		}
	}
end

t[#t+1] = Def.Sprite{
	Texture='ScoreFrame.png',
}

for i=1,6 do
	t[#t+1] = RivalScore(pn, i) .. {
		InitCommand=function(self)
			self:y((i*43)-150)
		end
	}
end

return t