local args = {...}
local pn = args[1]
local text = args[2]

local enabledPlayers = GAMESTATE:GetEnabledPlayers()
local isSoloPlayer = #enabledPlayers == 1 and enabledPlayers[1] == pn

local NameEntryWrapper
local NameEntry

local function OpenNameEntry()
  SCREENMAN:set_input_redirected(pn, true)
  setenv('NameEntryOpen' .. pn, 1) -- This env lets other active InputCallbacks detect whenever NameEntry is open
  NameEntryWrapper:playcommand('Show')
end
local function CloseNameEntry()
  SCREENMAN:set_input_redirected(pn, false)
  setenv('NameEntryOpen' .. pn, 0)
  NameEntryWrapper:playcommand('Hide')
end

local t = Def.ActorFrame{
  -- Wrap in a simple ActorFrame so upstream can append their own InitCommand, ShowCommand, and HideCommand
  Def.ActorFrame{
    InitCommand=function(self)
      NameEntryWrapper = self:GetParent()
      
      NameEntryWrapper:draworder(10)
      NameEntryWrapper:visible(false)
      CloseNameEntry()
    end,
    ShowCommand=function()
      NameEntryWrapper:visible(true)
    end,
    HideCommand=function()
      NameEntryWrapper:sleep(0.1):queuecommand('MakeInvisible')
    end,
    MakeInvisibleCommand=function()
      NameEntryWrapper:visible(false)
      if NameEntry then
          NameEntry:Reset()
      end
    end,
    OnCommand=function(self)
      -- Because SCREENMAN:set_input_redirected(pn, true) also blocks CodeMessageCommand inputs we have to use a 
      -- InputCallback to recieve inputs while it's active.
      local screen = Var('LoadingScreen')
      local openButton = THEME:GetMetric(screen, 'OpenNameEntryButton')
      local closeButton = THEME:GetMetric(screen, 'CloseNameEntryButton')
      self.InputHandler = function(event)
        if event.PlayerNumber ~= pn then return end
        if ToEnumShortString(event.type) ~= 'FirstPress' then return end
        local button = event.GameButton
        if not button or button == '' then return end
        local isOpen = getenv('NameEntryOpen' .. pn) == 1
        
        if isOpen then
          if button == openButton or button == closeButton then
            CloseNameEntry()
          end
        else
          if button == openButton then
            OpenNameEntry()
          end
        end
      end
      SCREENMAN:GetTopScreen():AddInputCallback(self.InputHandler)
    end,
    OffCommand=function(self)
      SCREENMAN:GetTopScreen():RemoveInputCallback(self.InputHandler)
    end,
    loadfile(THEME:GetPathB('', '_NameEntry/frame')){
      Player=pn,
      AllowKeyboard=(isSoloPlayer or pn == PLAYER_1),
      AllowInputCallback=function(self)
        return getenv('NameEntryOpen' .. pn) == 1
      end,
      EnterCallback=function(self)
        CloseNameEntry()
      end,
      InitCommand=function(self)
        -- Since we're just passing this options table to the NameEntry module, then this InitCommand
        -- will be on the NameEntry object itself. We can therefore get the NameEntry object here.
        NameEntry = self
      end,
      Text=text,
    },
  },
}

return t, OpenNameEntry, CloseNameEntry