local function WheelMove(mov)
  local mw = SCREENMAN:GetTopScreen():GetChild("MusicWheel");
  mw:Move(mov)
end

local screen = Var"LoadingScreen"

local heldButtonsPerPlayer = {}
local function SetHeld(pn, button, state)
  local heldButtons = heldButtonsPerPlayer[pn]
  if not heldButtons then
    heldButtons = {}
    heldButtonsPerPlayer[pn] = heldButtons
  end
  heldButtons[button] = state
end
local function IsHeld(pn, button)
  local heldButtons = heldButtonsPerPlayer[pn]
  if not heldButtons then return false end
  return not not heldButtons[button]
end

local function InputHandler(event)
  local player = event.PlayerNumber
  local MusicWheel = SCREENMAN:GetTopScreen("ScreenSelectMusic"):GetChild("MusicWheel");
  local overlay = SCREENMAN:GetTopScreen()
  local button = event.GameButton
  
  if button and button ~= '' then
    local pressType = ToEnumShortString(event.type)
    if pressType == 'FirstPress' or pressType == 'Repeat' then
      SetHeld(player, button, true)
    elseif pressType == 'Release' then
      SetHeld(player, button, false)
    end
    
    -- Close song group as soon as we get the FirstPress while holding down Select. "@Select-MenuUp" CodeDetector only 
    -- works if we release Select just after the FirstPress. Doing this in an InputCallback makes it more responsive.
    if MusicWheel and IsHeld(player, 'Select') and button == 'MenuUp' and pressType == 'FirstPress' then
      MusicWheel:SetOpenSection('')
      
      if ThemePrefs.Get('WheelType') == 'A' then
        MusicWheel:Move(1) -- Move one step down to cancel out the default MenuUp action
      end
    end
  end
  
  if event.type == "InputEventType_Release" then return false end
  if event.DeviceInput.button == "DeviceButton_left mouse button" then
    MESSAGEMAN:Broadcast("MouseLeftClick")
  end
  if MusicWheel ~= nil and getenv("OPList") == 0 then
    if ThemePrefs.Get("WheelType") == "A" then
      if event.GameButton == "MenuLeft" and GAMESTATE:IsPlayerEnabled(player) then
        overlay:GetChild("MWChange"):play()
      end
      if event.GameButton == "MenuRight" and GAMESTATE:IsPlayerEnabled(player) then
        overlay:GetChild("MWChange"):play()
      end
      if event.GameButton == "MenuDown" and GAMESTATE:IsPlayerEnabled(player) and PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") then
        if MusicWheel:GetSelectedType() == 'WheelItemDataType_Song' then
          WheelMove(3)
          if MusicWheel:GetSelectedType() ~= 'WheelItemDataType_Song' then
            WheelMove(-2)
            if MusicWheel:GetSelectedType() == "WheelItemDataType_Song" then
              WheelMove(2)
              if MusicWheel:GetSelectedType() ~= "WheelItemDataType_Song" then
                WheelMove(-1)
                if MusicWheel:GetSelectedType() == "WheelItemDataType_Song" then
                  WheelMove(1)
                end
              end
            end
          end
        else
          MusicWheel:Move(1)
        end
        MusicWheel:Move(0)
        overlay:GetChild("MWChange"):play()
      end
      if event.GameButton == "MenuUp" and GAMESTATE:IsPlayerEnabled(player) and PREFSMAN:GetPreference("OnlyDedicatedMenuButtons") then
        if MusicWheel:GetSelectedType() == 'WheelItemDataType_Song' then
          WheelMove(-3)
          if MusicWheel:GetSelectedType() ~= 'WheelItemDataType_Song' then
            WheelMove(2)
            if MusicWheel:GetSelectedType() == "WheelItemDataType_Song" then
              WheelMove(-2)
              if MusicWheel:GetSelectedType() ~= "WheelItemDataType_Song" then
                WheelMove(1)
                if MusicWheel:GetSelectedType() == "WheelItemDataType_Song" then
                  WheelMove(-1)
                end
              end
            end
          end
        else
          WheelMove(-1)
        end
        WheelMove(0)
        overlay:GetChild("MWChange"):play()
      end
    end
  end
end

setenv("OPOpened",0)
setenv("DList",0)
return Def.ActorFrame{
  OnCommand=function(self)
    SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
    SCREENMAN:GetTopScreen():AddInputCallback(DDRInput(self))
  end;
  OffCommand=function(self) 
    SCREENMAN:GetTopScreen():RemoveInputCallback(InputHandler)
    SCREENMAN:GetTopScreen():RemoveInputCallback(DDRInput(self))
    heldButtonsPerPlayer = {}
  end,
  SongChosenMessageCommand=function(self) setenv("DList",1) self:playcommand("Off") end;
  SongUnchosenMessageCommand=function(self)
    setenv("DList",0)
    self:sleep(0.5):queuecommand("On");
  end;
  MouseLeftClickMessageCommand = function(self)
    if ThemePrefs.Get("Touch") == true then
      self:queuecommand("PlayTopPressedActor")
    end
  end;
  --[[StartReleaseCommand=function(s)
    local song = GAMESTATE:GetCurrentSong()
    local mw = SCREENMAN:GetTopScreen():GetChild("MusicWheel")
    if song and getenv("OPList") == 0 then
      if not ShowTwoPart() and getenv("SortList") == 0 then
        SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_MenuTimer")
      else
      end
    end
  end,]]
  BackRepeatCommand=function(s)
    if getenv("OPList") == 0 and getenv("DList") == 0 then 
      SCREENMAN:GetTopScreen():Cancel()
    end
  end,
  StartRepeatCommand=function(s)
    local mw = SCREENMAN:GetTopScreen():GetChild("MusicWheel")
    local song = GAMESTATE:GetCurrentSong()
    if song then
      if GAMESTATE:IsPlayerEnabled(PLAYER_1) then
        if ShowTwoPart() and getenv("OPStop") == 0 then
          SCREENMAN:GetTopScreen():OpenOptionsList(PLAYER_1)
        else
          SCREENMAN:GetTopScreen():OpenOptionsList(PLAYER_1)
        end
      end
      if GAMESTATE:IsPlayerEnabled(PLAYER_2) then 
        if ShowTwoPart() and getenv("OPStop") == 0 then
          SCREENMAN:GetTopScreen():OpenOptionsList(PLAYER_2)
        else
          SCREENMAN:GetTopScreen():OpenOptionsList(PLAYER_2)
        end
      end
    end
  end,
  PlayTopPressedActorCommand = function(self)
    playTopPressedActor()
    resetPressedActors()
  end;
  loadfile(THEME:GetPathB("","_cursor"))();
};

--[[
local function WheelMove(mov)
  local mw = SCREENMAN:GetTopScreen():GetChild("MusicWheel");
	mw:Move(mov)
end

local t = Def.ActorFrame{
  OnCommand=function(self) SCREENMAN:GetTopScreen():AddInputCallback(DDRInput(self))
  OffCommand=function(self)
    SCREENMAN:GetTopScreen():RemoveInputCallback(DDRInput(self))
  end;
  SongChosenMessageCommand=function(self) self:queuecommand("Off") end;
  SongUnchosenMessageCommand=function(self)
    self:sleep(0.5):queuecommand("On");
  end;
  StartReleaseCommand=function(self)
	  local mw = SCREENMAN:GetTopScreen("ScreenSelectMusic"):GetChild("MusicWheel");
    local song = GAMESTATE:GetCurrentSong() 
    if ThemePrefs.Get("WheelType") == "Jukebox" or ThemePrefs.Get("WheelType") == "Wheel" then
		  if song then
        SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_MenuTimer")
      end
    else
		end;
  end;
  StartRepeatCommand=function(self)
    local mw = SCREENMAN:GetTopScreen():GetChild("MusicWheel")
    local song = GAMESTATE:GetCurrentSong()
    if song then
      if ThemePrefs.Get("WheelType") == "Jukebox" or ThemePrefs.Get("WheelType") == "Wheel" then
        SCREENMAN:AddNewScreenToTop("ScreenPlayerOptionsPopup","SM_MenuTimer")
      else
        SCREENMAN:AddNewScreenToTop("ScreenPlayerOptionsPopup")
      end
    else
    end;
  end;
  SongUnchosenMessageCommand=function(self)
    self:sleep(0.5):queuecommand("On");
  end;
};]]
