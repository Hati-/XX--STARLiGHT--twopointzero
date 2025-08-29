-- Thank you for using this project.
-- Please consider all the effort that has been made, so remember to play fair.
-- Enjoy! See you later alligator.
-- Author: Enciso0720
-- Last Update: 20230813

--[[
XXX:
	This file has to be loaded after "99 Characters.lua", so we can overwrite functions such as OptionRowCharacters(),
	hence the "999" in the filename. It would be nice to just replace the file, but that would break other parts of the
	theme that expect the functions defined inside "99 Characters.lua".
	The final solution would be to have support for both character systems and use a flag to switch between them, but
	that would require a lot of work, and there are other priorities right now.
--]]

function GetDanceStagesDirPath()
  return '/DanceStages/'
end

function GetCharactersDirPath()
  return '/Characters/'
end

function HasAnyCharacters(pn)
  return GAMESTATE:IsPlayerEnabled(pn) and GAMESTATE:GetCharacter(pn):GetDisplayName() ~= 'default'
end

function AnyoneHasChar()
  return (HasAnyCharacters(PLAYER_1) or HasAnyCharacters(PLAYER_2))
end

function BothPlayersEnabled()
  return GAMESTATE:IsPlayerEnabled(PLAYER_1) and GAMESTATE:IsPlayerEnabled(PLAYER_2)
end

function DancerMateEnabled()
  if GAMESTATE:IsPlayerEnabled(PLAYER_1) and GetUserPref('DancerMate') ~= 'None' then
    return true
  else
    return false
  end
end

function ResetCamera()
  local cFOV = 90
  if THEME:GetMetric('Common', 'ScreenHeight') >= 1080 then
    cFOV = 91.3
  end
  return Camera:fov(cFOV):rotationy(180):rotationx(0):rotationz(0):Center():z(WideScale(300, 400)):addy(10):stopeffect()
end

DEDICHAR = {}

function DEDICHAR:SetTimingData()
  setenv('song', GAMESTATE:GetCurrentSong())
  setenv('start', getenv('song'):GetFirstBeat())
  setenv('now', GAMESTATE:GetSongBeat())
end

Config = {}

function Config.Load(key, file)
  if not FILEMAN:DoesFileExist(file) then
    return false
  end

  local Container = {}

  local configfile = RageFileUtil.CreateRageFile()
  configfile:Open(file, 1)

  local configcontent = configfile:Read()

  configfile:Close()
  configfile:destroy()

  for line in string.gmatch(configcontent .. '\n', '(.-)\n') do
    for KeyVal, Val in string.gmatch(line, '(.-)=(.+)') do
      if key == KeyVal then
        return Val
      end
    end
  end
end

function SlowMotion(self)
  local SPos = GAMESTATE:GetSongPosition()

  if not SPos:GetFreeze() and not SPos:GetDelay() then
    self:SetUpdateRate(1)
  else
    self:SetUpdateRate(0.1)
  end
end

function setenv(name, value)
  GAMESTATE:Env()[name] = value
end
function getenv(name)
  return GAMESTATE:Env()[name]
end

function HasVideo()
  local videoFileExtensions = { 'mp4', 'avi', 'mov', 'm2ts', 'm2v', 'wmv', 'mpg', 'mpeg' }
  
  local song = GAMESTATE:GetCurrentSong()
  local path = song and song:GetMusicPath()
  if not path then -- both GetCurrentSong() and GetMusicPath() can return nil
    return false
  end
  path = path:gsub('%.%w+$', '') .. '.' -- remove file extension and append a dot
  
  for _, ext in ipairs(videoFileExtensions) do
    if FILEMAN:DoesFileExist(path .. ext) then
      return true
    end
  end
  return false
end

function PotentialModSong()
  local folder = FILEMAN:GetDirListing(GAMESTATE:GetCurrentSong():GetSongDir(), false, false)
  local bgchanges = GAMESTATE:GetCurrentSong():GetBGChanges()
  local attacks = GAMESTATE:GetCurrentSong():HasAttacks()

  for i = 1, #folder do
    if string.match(folder[i], 'lua') or (#bgchanges > 2) or attacks then
      return true
    end
  end
  return false
end

function VideoStage()
  if string.match(DanceStage, 'MOVIE')
  or string.match(DanceStage, 'REPLICANT')
  or string.match(DanceStage, 'BIG SCREEN')
  or string.match(DanceStage, 'CAPTURE ME') then
    return true
  end
  return false
end

------------------------

function IndexKey(tab, el)
  for index, value in pairs(tab) do
    if value == el then
      return index
    end
  end
end

local charactersSortOrder = {
  '%(A%)',
  '%(X2%)',
  '%(X%)',
  '%(SN2%)',
  '%(SN%)',
  '%[PiX%]',
  '%[JB%]',
  '%[DW%]',
  '%(DDRII%)',
  '%[DDRII%]',
  '%(HP4%)',
  '%[HP4%]',
  '%(HP3%)',
  '%[HP3%]',
  '%(HP2%)',
  '%[HP2%]',
  '%(HP1%)',
  '%[HP1%]',
  '%(HP%)',
  '%[HP%]',
  '%(WINX%)',
  '%[WINX%]',
  '%(5th%)',
  '%(4th%)',
  '%(3rd%)',
  '%(2nd%)',
  '%(1st%)',
  '%(CUSTOM%)',
}

local function charactersSortFunc(a, b)
  for _, pattern in ipairs(charactersSortOrder) do
    local aMatches = string.match(a, pattern) ~= nil
    local bMatches = string.match(b, pattern) ~= nil
    if aMatches and not bMatches then
      return true
    elseif bMatches and not aMatches then
      return false
    end
  end
end

function GetAllCharacterNames()
  local charactersDirPath = GetCharactersDirPath()
  
  local characterDirs = FILEMAN:GetDirListing(charactersDirPath, true, false)
  for i = #characterDirs, 1, -1 do -- Iterate backwards so we don't skip elements when removing
    local dirName = characterDirs[i]
    if dirName == 'DanceRepo'
    or dirName == 'default'
    or not FILEMAN:DoesFileExist(charactersDirPath .. dirName .. '/model.txt') then
      table.remove(characterDirs, i)
    end
  end
  
  table.sort(characterDirs, charactersSortFunc)
  table.insert(characterDirs, 1, 'Random')
  return characterDirs
end

function OptionRowCharacters()
  local choiceList = GetAllCharacterNames()
  local t = {
    Name = 'Characters',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = false,
    ExportOnChange = false,
    Choices = choiceList,

    LoadSelections = function(self, list, pn)
      if GetUserPref('SelectCharacter' .. pn) == nil or tonumber(GetUserPref('SelectCharacter' .. pn)) then
        SetUserPref('SelectCharacter' .. pn, 'Random')
      end
      local Load = GetUserPref('SelectCharacter' .. pn)
      list[IndexKey(choiceList, Load)] = true
    end,

    SaveSelections = function(self, list, pn)
      for number = 0, 999 do
        if list[number] then
          WritePrefToFile('SelectCharacter' .. pn, choiceList[number])
          break
        end
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function ResolveCharacterName(pn)
  local name = GetUserPref('SelectCharacter' .. pn)
  return name
end

function WhichRead(pn)
  if GetUserPref('SelectCharacter' .. pn) == 'Random' then
    return GetUserPref('CharaRandom' .. pn)
  else
    return GetUserPref('SelectCharacter' .. pn)
  end
end

function RandomCharacter(pn)
  if ResolveCharacterName(pn) == 'Random' then
    ChoiceList = GetAllCharacterNames()
    table.remove(ChoiceList, IndexKey(ChoiceList, 'default'))
    table.remove(ChoiceList, IndexKey(ChoiceList, 'None'))
    setenv('ChoiceRandom' .. pn, ChoiceList[math.random(#ChoiceList)])
  end
end

local danceStagesSortOrder = {
  '%(A%)',
  '%(X2%)',
  '%(X%)',
  '%(REPLICANT%)',
  '%(2014%)',
  '%(SN%)',
  '%(DDRII%)',
  '%[DDRII%]',
  '%(HP4%)',
  '%[HP4%]',
  '%(HP3%)',
  '%[HP3%]',
  '%(HP2%)',
  '%[HP2%]',
  '%(HP1%)',
  '%[HP1%]',
  '%(HP%)',
  '%[HP%]',
  '%(WINX%)',
  '%[WINX%]',
  '%(CUSTOM%)',
}

local function danceStagesSortFunc(a, b)
  for _, pattern in ipairs(danceStagesSortOrder) do
    local aMatches = string.match(a, pattern) ~= nil
    local bMatches = string.match(b, pattern) ~= nil
    if aMatches and not bMatches then
      return true
    elseif bMatches and not aMatches then
      return false
    end
  end
end

function GetAllDanceStagesNames()
  local danceStagesDirPath = GetDanceStagesDirPath()
  
  local danceStageDirs = FILEMAN:GetDirListing(danceStagesDirPath, true, false)
  for i = #danceStageDirs, 1, -1 do -- Iterate backwards so we don't skip elements when removing
    local dirName = danceStageDirs[i]
    if dirName == 'StageMovies'
    or not FILEMAN:DoesFileExist(danceStagesDirPath .. dirName .. '/LoaderA.lua')
    or not FILEMAN:DoesFileExist(danceStagesDirPath .. dirName .. '/Cameras.lua') then
      table.remove(danceStageDirs, i)
    end
  end
  
  table.sort(danceStageDirs, danceStagesSortFunc)
  table.insert(danceStageDirs, 1, 'DEFAULT')
  table.insert(danceStageDirs, 2, 'RANDOM')
  return danceStageDirs
end

DanceStage = nil -- Global variable to hold the current DanceStage
local DanceStageSeed
function UpdateDanceStageFromSelection()
  local StageSeed = GAMESTATE:GetStageSeed()
  if DanceStage then
    if DanceStageSeed == StageSeed then
      Trace('Stage Seed is the same, not re-evaluating DanceStage')
      return
    else
      DanceStage = nil
    end
  end
  DanceStageSeed = StageSeed
  
  local DanceStagesDir = GetAllDanceStagesNames()
  table.remove(DanceStagesDir, IndexKey(DanceStagesDir, 'DEFAULT'))
  table.remove(DanceStagesDir, IndexKey(DanceStagesDir, 'RANDOM'))
  local DanceStageSelected = GetUserPref('SelectDanceStage')

  if DanceStageSelected == 'DEFAULT' or GAMESTATE:IsDemonstration() then
    DanceStage = DanceStageSong()
  elseif DanceStageSelected == 'RANDOM' then
    DanceStage = DanceStagesDir[math.random(#DanceStagesDir)]
  else
    DanceStage = GetUserPref('SelectDanceStage')
  end

  if not DanceStage or IndexKey(DanceStagesDir, DanceStage) == nil then
    Trace('Invalid DanceStage "'..tostring(DanceStage)..'", re-selecting a random one')
    DanceStage = DanceStagesDir[math.random(#DanceStagesDir)]
  end

  Trace('DanceStage set to: ' .. tostring(DanceStage) .. ' (Stage Seed: ' .. tostring(DanceStageSeed) .. ')')
end

function SelectDanceStage()
  local choiceListDS = GetAllDanceStagesNames()
  local t = {
    Name = 'DanceStage',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = choiceListDS,

    LoadSelections = function(self, list, pn)
      if GetUserPref('SelectDanceStage') == nil then
        SetUserPref('SelectDanceStage', 'DEFAULT')
      end
      local DSLoad = GetUserPref('SelectDanceStage')
      list[IndexKey(choiceListDS, DSLoad)] = true
    end,

    SaveSelections = function(self, list, pn)
      for number = 0, 999 do
        if list[number] then
          WritePrefToFile('SelectDanceStage', choiceListDS[number])
        end
      end
    end,
   }
  setmetatable(t, t)
  return t
end

--------------------

function CutInOverVideo()
  local t = {
    Name = 'CutInOverVideo',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = { 'ON', 'OFF' },
    LoadSelections = function(self, list, pn)
      if ReadPrefFromFile('CutInOverVideo') ~= nil then
        if GetUserPref('CutInOverVideo') == 'ON' then
          list[1] = true
        elseif GetUserPref('CutInOverVideo') == 'OFF' then
          list[2] = true
        else
          list[1] = true
        end
      else
        WritePrefToFile('CutInOverVideo', 'OFF')
        list[2] = true
      end
    end,
    SaveSelections = function(self, list, pn)
      if list[1] then
        WritePrefToFile('CutInOverVideo', 'ON')
      elseif list[2] then
        WritePrefToFile('CutInOverVideo', 'OFF')
      else
        WritePrefToFile('CutInOverVideo', 'ON')
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function VideoOverStage()
  local t = {
    Name = 'VideoOverStage',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = { 'ON', 'OFF' },
    LoadSelections = function(self, list, pn)
      if ReadPrefFromFile('VideoOverStage') ~= nil then
        if GetUserPref('VideoOverStage') == 'ON' then
          list[1] = true
        elseif GetUserPref('VideoOverStage') == 'OFF' then
          list[2] = true
        else
          list[1] = true
        end
      else
        WritePrefToFile('VideoOverStage', 'OFF')
        list[2] = true
      end
    end,
    SaveSelections = function(self, list, pn)
      if list[1] then
        WritePrefToFile('VideoOverStage', 'ON')
      elseif list[2] then
        WritePrefToFile('VideoOverStage', 'OFF')
      else
        WritePrefToFile('VideoOverStage', 'ON')
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function VoverS()
  if GetUserPref('VideoOverStage') == 'ON' then
    return true
  else
    return false
  end
end

function BoomSync()
  local t = {
    Name = 'BoomSync',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = { 'Normal', 'BPM Sync' },
    LoadSelections = function(self, list, pn)
      if ReadPrefFromFile('BoomSync') ~= nil then
        if GetUserPref('BoomSync') == 'Normal' then
          list[1] = true
        elseif GetUserPref('BoomSync') == 'BPM Sync' then
          list[2] = true
        else
          list[1] = true
        end
      else
        WritePrefToFile('BoomSync', 'Normal')
        list[1] = true
      end
    end,
    SaveSelections = function(self, list, pn)
      if list[1] then
        WritePrefToFile('BoomSync', 'Normal')
      elseif list[2] then
        WritePrefToFile('BoomSync', 'BPM Sync')
      else
        WritePrefToFile('BoomSync', 'Normal')
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function CharacterSync()
  local t = {
    Name = 'CharacterSync',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = { 'Normal', 'BPM Sync' },
    LoadSelections = function(self, list, pn)
      if ReadPrefFromFile('CharacterSync') ~= nil then
        if GetUserPref('CharacterSync') == 'Normal' then
          list[1] = true
        elseif GetUserPref('CharacterSync') == 'BPM Sync' then
          list[2] = true
        else
          list[1] = true
        end
      else
        WritePrefToFile('CharacterSync', 'Normal')
        list[1] = true
      end
    end,
    SaveSelections = function(self, list, pn)
      if list[1] then
        WritePrefToFile('CharacterSync', 'Normal')
      elseif list[2] then
        WritePrefToFile('CharacterSync', 'BPM Sync')
      else
        WritePrefToFile('CharacterSync', 'Normal')
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function DiscoStars()
  local t = {
    Name = 'DiscoStars',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = { 'Normal', 'A few', 'None' },
    LoadSelections = function(self, list, pn)
      if ReadPrefFromFile('DiscoStars') ~= nil then
        if GetUserPref('DiscoStars') == 'Normal' then
          list[1] = true
        elseif GetUserPref('DiscoStars') == 'A few' then
          list[2] = true
        elseif GetUserPref('DiscoStars') == 'None' then
          list[3] = true
        else
          list[1] = true
        end
      else
        WritePrefToFile('DiscoStars', 'Normal')
        list[1] = true
      end
    end,
    SaveSelections = function(self, list, pn)
      if list[1] then
        WritePrefToFile('DiscoStars', 'Normal')
      elseif list[2] then
        WritePrefToFile('DiscoStars', 'A few')
      elseif list[3] then
        WritePrefToFile('DiscoStars', 'None')
      else
        WritePrefToFile('DiscoStars', 'Normal')
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function RMStage()
  local t = {
    Name = 'RMStage',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = { 'Random Movies', 'Jacket' },
    LoadSelections = function(self, list, pn)
      if ReadPrefFromFile('RMStage') ~= nil then
        if GetUserPref('RMStage') == 'Random Movies' then
          list[1] = true
        elseif GetUserPref('RMStage') == 'Jacket' then
          list[2] = true
        else
          list[1] = true
        end
      else
        WritePrefToFile('RMStage', 'Jacket')
        list[2] = true
      end
    end,
    SaveSelections = function(self, list, pn)
      if list[1] then
        WritePrefToFile('RMStage', 'Random Movies')
      elseif list[2] then
        WritePrefToFile('RMStage', 'Jacket')
      else
        WritePrefToFile('RMStage', 'Random Movies')
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function CharaShadow()
  local t = {
    Name = 'CharaShadow',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = { 'ON', 'OFF' },
    LoadSelections = function(self, list, pn)
      if ReadPrefFromFile('CharaShadow') ~= nil then
        if GetUserPref('CharaShadow') == 'ON' then
          list[1] = true
        elseif GetUserPref('CharaShadow') == 'OFF' then
          list[2] = true
        else
          list[1] = true
        end
      else
        WritePrefToFile('CharaShadow', 'ON')
        list[1] = true
      end
    end,
    SaveSelections = function(self, list, pn)
      if list[1] then
        WritePrefToFile('CharaShadow', 'ON')
      elseif list[2] then
        WritePrefToFile('CharaShadow', 'OFF')
      else
        WritePrefToFile('CharaShadow', 'ON')
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function SNEnv()
  local t = {
    Name = 'SNEnv',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = { 'Intense', 'Colored', 'Normal' },
    LoadSelections = function(self, list, pn)
      if ReadPrefFromFile('SNEnv') ~= nil then
        if GetUserPref('SNEnv') == 'Intense' then
          list[1] = true
        elseif GetUserPref('SNEnv') == 'Colored' then
          list[2] = true
        elseif GetUserPref('SNEnv') == 'Normal' then
          list[3] = true
        else
          list[1] = true
        end
      else
        WritePrefToFile('SNEnv', 'Intense')
        list[1] = true
      end
    end,
    SaveSelections = function(self, list, pn)
      if list[1] then
        WritePrefToFile('SNEnv', 'Intense')
      elseif list[2] then
        WritePrefToFile('SNEnv', 'Colored')
      elseif list[3] then
        WritePrefToFile('SNEnv', 'Normal')
      else
        WritePrefToFile('SNEnv', 'Intense')
      end
    end,
   }
  setmetatable(t, t)
  return t
end

--------------------

function Mate1()
  local choiceList = GetAllCharacterNames()
  local t = {
    Name = 'Mate1',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = choiceList,

    LoadSelections = function(self, list, pn)
      if GetUserPref('Mate1') == nil then
        SetUserPref('Mate1', 'None')
      end
      local DMLoad = GetUserPref('Mate1')
      list[IndexKey(choiceList, DMLoad)] = true
    end,

    SaveSelections = function(self, list, pn)
      for number = 0, 999 do
        if list[number] then
          WritePrefToFile('Mate1', choiceList[number])
        end
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function Mate2()
  local choiceList = GetAllCharacterNames()
  local t = {
    Name = 'Mate2',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = choiceList,

    LoadSelections = function(self, list, pn)
      if GetUserPref('Mate2') == nil then
        SetUserPref('Mate2', 'None')
      end
      local DMLoad = GetUserPref('Mate2')
      list[IndexKey(choiceList, DMLoad)] = true
    end,

    SaveSelections = function(self, list, pn)
      for number = 0, 999 do
        if list[number] then
          WritePrefToFile('Mate2', choiceList[number])
        end
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function Mate3()
  local choiceList = GetAllCharacterNames()
  local t = {
    Name = 'Mate3',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = choiceList,

    LoadSelections = function(self, list, pn)
      if GetUserPref('Mate3') == nil then
        SetUserPref('Mate3', 'None')
      end
      local DMLoad = GetUserPref('Mate3')
      list[IndexKey(choiceList, DMLoad)] = true
    end,

    SaveSelections = function(self, list, pn)
      for number = 0, 999 do
        if list[number] then
          WritePrefToFile('Mate3', choiceList[number])
        end
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function Mate4()
  local choiceList = GetAllCharacterNames()
  local t = {
    Name = 'Mate4',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = choiceList,

    LoadSelections = function(self, list, pn)
      if GetUserPref('Mate4') == nil then
        SetUserPref('Mate4', 'None')
      end
      local DMLoad = GetUserPref('Mate4')
      list[IndexKey(choiceList, DMLoad)] = true
    end,

    SaveSelections = function(self, list, pn)
      for number = 0, 999 do
        if list[number] then
          WritePrefToFile('Mate4', choiceList[number])
        end
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function Mate5()
  local choiceList = GetAllCharacterNames()
  local t = {
    Name = 'Mate5',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = choiceList,

    LoadSelections = function(self, list, pn)
      if GetUserPref('Mate5') == nil then
        SetUserPref('Mate5', 'None')
      end
      local DMLoad = GetUserPref('Mate5')
      list[IndexKey(choiceList, DMLoad)] = true
    end,

    SaveSelections = function(self, list, pn)
      for number = 0, 999 do
        if list[number] then
          WritePrefToFile('Mate5', choiceList[number])
        end
      end
    end,
   }
  setmetatable(t, t)
  return t
end

function Mate6()
  local choiceList = GetAllCharacterNames()
  local t = {
    Name = 'Mate6',
    LayoutType = 'ShowAllInRow',
    SelectType = 'SelectOne',
    OneChoiceForAllPlayers = true,
    ExportOnChange = false,
    Choices = choiceList,

    LoadSelections = function(self, list, pn)
      if GetUserPref('Mate6') == nil then
        SetUserPref('Mate6', 'None')
      end
      local DMLoad = GetUserPref('Mate6')
      list[IndexKey(choiceList, DMLoad)] = true
    end,

    SaveSelections = function(self, list, pn)
      for number = 0, 999 do
        if list[number] then
          WritePrefToFile('Mate6', choiceList[number])
        end
      end
    end,
   }
  setmetatable(t, t)
  return t
end
