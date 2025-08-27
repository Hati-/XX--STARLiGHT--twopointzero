-- Thank you for using this project.
-- Please consider all the effort that has been made, so remember to play fair.
-- Enjoy! See you later alligator.
-- Author: Enciso0720
-- Last Update: 20230813
local StagesFolder = '/DanceStages/'

local gFOV = 90
if THEME:GetMetric('Common', 'ScreenHeight') >= 1080 then
  gFOV = 91.3
end

local t = Def.ActorFrame {
  SPos = GAMESTATE:GetSongPosition(),

  OnCommand = function(self)
    self:Center():fov(gFOV)
    Camera = self
    if not (HasVideo() and not IsLuaVersionAtLeast(5, 3)) then
      Camera:SetUpdateFunction(SlowMotion)
    end
  end,
 }

------- DANCESTAGE SELECTION -------
UpdateDanceStageFromSelection()

------- VIDEO/BACKGROUND VS STAGE  -------
local SBG = GAMESTATE:GetSongOptionsObject('ModsLevel_Preferred')
if (not HasVideo() and PotentialModSong()) then
  --SBG:StaticBackground(false)
  PREFSMAN:SetPreference('SongBackgrounds', true)
elseif (HasVideo() and not VideoStage() and VoverS()) then
  --SBG:StaticBackground(false)
  PREFSMAN:SetPreference('SongBackgrounds', true)
elseif (HasVideo() and not VideoStage() and not VoverS()) then
  --SBG:StaticBackground(true)
  PREFSMAN:SetPreference('SongBackgrounds', false)
else
  --SBG:StaticBackground(true)
  PREFSMAN:SetPreference('SongBackgrounds', false)
end
SBG:RandomBGOnly(false)


------- RANDOM CHARACTER -------
local CharaRandom = GetAllCharacterNames()
table.remove(CharaRandom,IndexKey(CharaRandom,'Random'))
table.remove(CharaRandom,IndexKey(CharaRandom,'None'))

for pn in ivalues(GAMESTATE:GetEnabledPlayers()) do
    if GetUserPref('SelectCharacter'..pn) == 'Random' then
        WritePrefToFile('CharaRandom'..pn,CharaRandom[math.random(#CharaRandom)]);
    end
end

------- DANCESTAGE LOADER -------
if (not HasVideo() and not PotentialModSong()) or (HasVideo() and VideoStage() and not PotentialModSong()) or
  (HasVideo() and not VideoStage() and not VoverS()) then

  ------- DANCESTAGE LOADER 1 -------

  t[#t + 1] = LoadActor(StagesFolder .. DanceStage .. '/LoaderA.lua')

  -------------- CHARACTERS --------------

  t[#t + 1] = LoadActor('Characters')

  ------- DANCESTAGE LOADER 2 -------

  if FILEMAN:DoesFileExist(StagesFolder .. DanceStage .. '/LoaderB.lua') then
    t[#t + 1] = LoadActor(StagesFolder .. DanceStage .. '/LoaderB.lua')
  end

  ------- CAMERA -------

  t[#t + 1] = LoadActor(StagesFolder .. DanceStage .. '/Cameras.lua')

  CamRan = 1
  local CameraRandomList = {}

  for i = 1, NumCameras do
    CameraRandomList[i] = i
  end

  for i = 1, NumCameras do
    local CamRandNumber = math.random(1, NumCameras)
    local TempRand = CameraRandomList[i]
    CameraRandomList[i] = CameraRandomList[CamRandNumber]
    CameraRandomList[CamRandNumber] = TempRand
  end

  t[#t + 1] = Def.Quad {
    OnCommand = function(self)
      self:visible(false):queuemessage('Camera' .. CameraRandomList[6]):sleep(WaitTime[CameraRandomList[6]])
        :queuecommand('TrackTime')
    end,
    TrackTimeCommand = function(self)
      DEDICHAR:SetTimingData()
      self:sleep(1 / 60)
      self:queuemessage('Camera' .. CameraRandomList[CamRan]):sleep(WaitTime[CameraRandomList[CamRan]])
      CurrentStageCamera = CurrentStageCamera
      CamRan = CamRan + 1
      if CamRan == NumCameras then
        CamRan = 1
      end
      self:queuecommand('TrackTime')
    end,
   }
end

return t
