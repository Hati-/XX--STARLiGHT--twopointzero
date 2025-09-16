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
local function CloseNameEntry(delay)
  SCREENMAN:set_input_redirected(pn, false)
  setenv('NameEntryOpen' .. pn, 0)
  if delay then
    NameEntryWrapper:sleep(delay):queuecommand('Hide')
  else
    NameEntryWrapper:playcommand('Hide')
  end
end

local t = Def.ActorFrame{
  -- Simple ActorFrame wrapper so upstream can add their own InitCommand, ShowCommand, HideCommand, and
  -- HideTweenDoneCommand etc.
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
    OnCommand=function(self)
      -- Because SCREENMAN:set_input_redirected(pn, true) also blocks CodeMessageCommand inputs we have to use a 
      -- InputCallback to recieve inputs while it's active.
      local screen = Var('LoadingScreen')
      local openButton
      local closeButton
      if screen then
        openButton = THEME:GetMetric(screen, 'OpenNameEntryButton')
        closeButton = THEME:GetMetric(screen, 'CloseNameEntryButton')
      end
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
      EnterCallback=function(self, params)
        -- Have a small close delay so the users can see the default name being used when NameEntry is left blank
        local delay = params.IsDefaultName and 0.5 or 0.1
        CloseNameEntry(delay)
      end,
      InitCommand=function(self)
        -- Since we're just passing this options table to the NameEntry module, then this InitCommand
        -- will be on the NameEntry object itself. We can therefore get the NameEntry object here.
        NameEntry = self
      end,
      Text=text,
    }..{
      HideTweenDoneCommand=function()
        NameEntryWrapper:visible(false)
        if NameEntry then
            NameEntry:Reset()
        end
        
        -- Propogate the HideTweenDoneCommand upstream so they can also hook into HideTweenDoneCommand. 
        -- We can't use playcommand() and queuecommand() here due to how they work on ActorFrames. On ActorFrames they
        -- propagate commands to their children downstream recursively, even with ActorFrame:propagate(false), causing
        -- them to create an infinite recursion loop and lock the game up.
        -- Instead, lets get the command function directly and call it ourselves.
        local commandFunc = NameEntryWrapper:GetCommand('HideTweenDone')
        if type(commandFunc) == 'function' then
          commandFunc(NameEntryWrapper)
        end
      end
    },
  },
}

return t, OpenNameEntry, CloseNameEntry