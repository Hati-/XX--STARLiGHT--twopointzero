local DEBUG = false

if StarlightCache and StarlightCache.NameEntry and not DEBUG then
  return StarlightCache.NameEntry
end
local NameEntry = {}
StarlightCache.NameEntry = NameEntry

-- Some hardcoded configuration constants
local MAX_RECENT_NAMES = 6
local RECENT_NAMES_COLS = 2
local RECENT_NAMES_MARGIN = 25
local SAVE_RECENT_NAMES_TO_DISK = true
local SAVE_RECENT_NAMES_NAMESPACE = 'NameEntry_RecentNames'

local DEFAULT_NAME = 'STEP'
local MAX_NAME_LENGTH = 8
local GRID_CELL_WIDTH = 50
local GRID_CELL_HEIGHT = 50

local KEY_CHARACTER_MAP = {
	{'A','B','C','D','E','F','G','H','I','J'},
	{'K','L','M','N','O','P','Q','R','S','T'},
	{'U','V','W','X','Y','Z'},
	{'0','1','2','3','4','5','6','7','8','9'},
	{'?','!','$','&','-','.','_','←','Enter'}
}
local SPECIAL_CHARACTERS = {'←', 'Enter'}

local KEY_WIDTH_MAP = {}
for keyY, _ in ipairs(KEY_CHARACTER_MAP) do KEY_WIDTH_MAP[keyY] = {} end
KEY_WIDTH_MAP[5][9] = 2 -- Enter

-- For testing
-- KEY_WIDTH_MAP[3][4] = 3 -- X
-- KEY_WIDTH_MAP[2][2] = 2 -- L

-- Generate lookup tables
for keyY, row in ipairs(KEY_CHARACTER_MAP) do
	local keyWidths = KEY_WIDTH_MAP[keyY]
	for keyX, _ in ipairs(row) do
		if keyWidths[keyX] == nil then
			keyWidths[keyX] = 1
		end
	end
end

local GRID_ROWS = 0
local GRID_COLS = 0
local GRID_TO_KEY_MAP = {}
for keyY, row in ipairs(KEY_WIDTH_MAP) do
	local keyXMap = {}
	GRID_TO_KEY_MAP[keyY] = keyXMap
	for keyX, width in ipairs(row) do
		for i=1, width do
			keyXMap[#keyXMap+1] = keyX
		end
	end
	GRID_ROWS = math.max(GRID_ROWS, keyY)
	GRID_COLS = math.max(GRID_COLS, #keyXMap)
end

local KEY_ROWS = 0
local KEY_COLS = 0
local KEY_TO_GRID_MAP = {}
for keyY, row in ipairs(KEY_WIDTH_MAP) do
	local gridXMap = {}
	KEY_TO_GRID_MAP[keyY] = gridXMap
	local gridX = 1
	for keyX, width in ipairs(row) do
		gridXMap[keyX] = gridX
		gridX = gridX + width
	end
	KEY_ROWS = math.max(KEY_ROWS, keyY)
	KEY_COLS = math.max(KEY_COLS, #gridXMap)
end

local SPECIAL_CHARACTERS_LOOKUP = {}
for i, character in ipairs(SPECIAL_CHARACTERS) do
	SPECIAL_CHARACTERS_LOOKUP[character] = true
end

local ENTER_KEY_POS = {}
local ALLOWED_CHARACTERS_LOOKUP = {}
for keyY, row in ipairs(KEY_CHARACTER_MAP) do
	for keyX, character in ipairs(row) do
    if character == 'Enter' then
      ENTER_KEY_POS.X = keyX
      ENTER_KEY_POS.Y = keyY
    end
		if not SPECIAL_CHARACTERS_LOOKUP[character] then
			ALLOWED_CHARACTERS_LOOKUP[character:lower()] = character
			ALLOWED_CHARACTERS_LOOKUP[character:upper()] = character
		end
	end
end

local RECENT_NAMES_GRID_WIDTH = GRID_COLS / RECENT_NAMES_COLS
local RECENT_NAMES_GRID_HEIGHT = 1

local RecentNames

local function TruncateRecentNames()
  -- Truncate list past the max limit
  for i = MAX_RECENT_NAMES + 1, #RecentNames do
    RecentNames[i] = nil
  end
end

local function SaveRecentNames()
  if SAVE_RECENT_NAMES_TO_DISK then
    local stringValue = table.concat(RecentNames, '\n')
    return SetUserPref(SAVE_RECENT_NAMES_NAMESPACE, stringValue)
  else
    _G[SAVE_RECENT_NAMES_NAMESPACE] = RecentNames
    return true
  end
end

local function LoadRecentNames()
  local success = false
  if SAVE_RECENT_NAMES_TO_DISK then
    local names = {}
    local stringValue = GetUserPref(SAVE_RECENT_NAMES_NAMESPACE)
    if stringValue then
      for name in string.gmatch(stringValue, '([^\n\r]+)') do
        name = name:gsub('^%s+', ''):gsub('%s+$', '') -- trim whitespace from start and end
        if name ~= '' then
          table.insert(names, name)
        end
      end
    end
    if #names > 0 then
      RecentNames = names
      success = true
    end
  else
    local RecentNames = _G[SAVE_RECENT_NAMES_NAMESPACE]
    success = true
  end
  
  if RecentNames then
    TruncateRecentNames()
  else
    -- If there's no recent names stored
    RecentNames = {}
    SaveRecentNames()
  end
  return success
end

-- Load recent names on startup
LoadRecentNames()

-- These are for testing
-- RecentNames[1] = nil
-- RecentNames[1] = 'A'
-- RecentNames[2] = 'B'
-- RecentNames[3] = 'C'
-- RecentNames[4] = 'D'
-- RecentNames[5] = 'E'
-- RecentNames[6] = 'F'

local function AddRecentName(name)
  if RecentNames[1] == name then return end
  
  -- See if name exists
  local pos
  for i = 1, #RecentNames do
    if RecentNames[i] == name then
      pos = i - 1
      break
    end
  end

  if not pos then
    -- Not found: shift whole list
    pos = #RecentNames
  end
  
  if pos > 0 then
    -- Shift block [1, pos] right by 1
    if table.move then
      table.move(RecentNames, 1, pos, 2)
    else
      for i = pos, 1, -1 do
        RecentNames[i + 1] = RecentNames[i]
      end
    end
  end
  
  RecentNames[1] = name
  
  TruncateRecentNames()
  SaveRecentNames()
end

local function GetNumRecentNamesRows()
  return math.floor((#RecentNames / RECENT_NAMES_COLS) + 0.5)
end

local function GetNumRecentNamesCols(recentNameRow)
  if recentNameRow then
    if recentNameRow < GetNumRecentNamesRows() then
      return RECENT_NAMES_COLS
    end
    return ((#RecentNames - 1) % RECENT_NAMES_COLS) + 1
  end
  return math.min(#RecentNames, RECENT_NAMES_COLS)
end

local function GetNumRecentNamesRows()
  return math.ceil(#RecentNames / RECENT_NAMES_COLS)
end

local function GridXYToKeyXY(gridX, gridY)
  local maxRows = GRID_ROWS + GetNumRecentNamesRows()
	if gridY < 1 or gridY > maxRows then
		error('GridXYToKeyXY(x, y): y-value out of range. Got '..gridY..', but expects range [1, '..maxRows..']')
	end
  local keyX, keyY
  if gridY <= GRID_ROWS then
    local keyXMap = GRID_TO_KEY_MAP[gridY]
    if gridX < 1 or gridX > #keyXMap then
      error('GridXYToKeyXY(x, y): x-value out of range. Got '..gridX..', but expects range [1, '..#keyXMap..']')
    end
    keyX = keyXMap[gridX]
  else
    local recentNamesRow = gridY - GRID_ROWS
    local numCols = RECENT_NAMES_COLS * RECENT_NAMES_GRID_WIDTH
    if gridX < 1 or gridX > numCols then
      error('GridXYToKeyXY(x, y): x-value out of range. Got '..gridX..', but expects range [1, '..numCols..']')
    end
    keyX = math.ceil(gridX / RECENT_NAMES_GRID_WIDTH)
  end
  
  keyY = gridY
  return keyX, keyY
end

local function GetKeyProperties(keyX, keyY)
  local maxRows = KEY_ROWS + GetNumRecentNamesRows()
	if keyY < 1 or keyY > maxRows then
		error('GetKeyProperties(x, y): y-value out of range. Got '..keyY..', but expects range [1, '..maxRows..']')
	end
  local x, y, width
  if keyY <= KEY_ROWS then
    local gridXMap = KEY_TO_GRID_MAP[keyY]
    if keyX < 1 or keyX > #gridXMap then
      error('GetKeyProperties(x, y): x-value out of range1. Got '..keyX..', but expects range [1, '..#gridXMap..']')
    end
    x = gridXMap[keyX] - 1
    width = KEY_WIDTH_MAP[keyY][keyX]
  else
    local recentNamesRow = keyY - KEY_ROWS
    local numCols = GetNumRecentNamesCols(recentNamesRow)
    if keyX < 1 or keyX > numCols then
      error('GetKeyProperties(x, y): x-value out of range2. Got '..keyX..', but expects range [1, '..numCols..']')
    end
    x = (keyX - 1) * RECENT_NAMES_GRID_WIDTH
    width = RECENT_NAMES_GRID_WIDTH
  end
  
  y = keyY - 1
  return x, y, width
end

local function GetSelectionBoxProperties(keyX, keyY)
	local x, y, width = GetKeyProperties(keyX, keyY)
	x = x * GRID_CELL_WIDTH + GRID_CELL_WIDTH / 2 * width
	y = y * GRID_CELL_HEIGHT + GRID_CELL_HEIGHT / 2
	width = width * GRID_CELL_WIDTH
	local height = GRID_CELL_HEIGHT
	
	local widthRatio = width/height
	if width/height >= 1.5 then
		-- Some minor corrections because the endBOX anx letterBOX textures aren't exactly uniform to eachother
		width = width*0.90
		height = height*0.74
		x = x - 1
		y = y + 1
	else
		width = width*0.82
		height = height*0.74
	end
  
  if keyY > KEY_ROWS then
    y = y + RECENT_NAMES_MARGIN
  end
  
	return x, y, width, height
end

local function wrap(x, n)
	if x < 0 then
		x = x + math.floor((-x / n) + 1) * n
	end
	return x % n
end
local function wrap1(x, n) -- Variant that works with indices starting at 1 instead of 0
	return wrap(x - 1, n) + 1
end

local isHoldingShift = false
local isHoldingCtrl = false
local function UpdateKeyModifiers(DeviceInput)
  local button = ToEnumShortString(DeviceInput.button):lower()
  if button == 'left shift' or button == 'right shift' then
    isHoldingShift = DeviceInput.down
  elseif button == 'left ctrl' or button == 'right ctrl' then
    isHoldingCtrl = DeviceInput.down
  end
end

--[[
  We can't get and use the computer's current keyboard layout because the INPUTMAN->DeviceInputToChar(...) function is 
  not exposed anywhere in Lua. The closest thing we have is to use ScreenTextEntry, but that is designed to work as a
  popup for text input.
  
  I tried to hack ScreenTextEntry to run in the background just to be a proxy for INPUTMAN->DeviceInputToChar(...), but
  I encountered two problems:
    - If we use SCREENMAN:AddNewScreenToTop("ScreenTextEntry") and make ScreenTextEntry a hidden top screen, then inputs
      for any underlying screen will be blocked which makes them unresponsive. This is due to how input handling for the
      screen stack works. We still want the underlying screen to be able to handle inputs themselves and be responsive
      while the NameEntry is active. Because of this input blocking, creating a hidden ScreenTextEntry popup with
      SCREENMAN:AddNewScreenToTop("ScreenTextEntry") doesn't work well if we just want to use it to capture keypresses
      and proxy INPUTMAN->DeviceInputToChar(...) in the background.
    - If we use the OverlayScreens metric to run ScreenTextEntry (or another screen that uses that class) as an overlay, 
      then inputs that ScreenTextEntry handles wont fall through to the current top screen. This is due to how overlay
      input handling works. ScreenTextEntry handles a lot of inputs such as the Start and Menu navigation keys which 
      means the current top screen will lose a lot of inputs and become really unresponsive as well. We therefore can't
      use the OverlayScreens metric to make a hidden a ScreenTextEntry overlay just to capture keyboard presses either.
  See: https://github.com/stepmania/stepmania/blob/d55acb1ba26f1c5b5e3048d6d6c0bd116625216f/src/ScreenManager.cpp#L537
  
  Alternatively we could make our own screen, for example a "ScreenNameEntry", that uses the ScreenTextEntry class and
  have it popup using SCREENMAN:AddNewScreenToTop("ScreenNameEntry"), but that requires us to change how we approach the
  NameEntry entirely. Things will also become tricky if we want support multiple players at the same time or scenarios
  were we don't want to block other player's input whenever a player is using ScreenNameEntry. Lets keep it simple and
  not do this for now.
  
  Currently, the most simple and flexible approach is to handle keyboard modifiers ourself and have our own keyboard
  layout. We can copy the default InputHandler::DeviceButtonToChar(...) behavior, which mimics the US keyboard layout:
  https://github.com/stepmania/stepmania/blob/d55acb1ba26f1c5b5e3048d6d6c0bd116625216f/src/arch/InputHandler/InputHandler.cpp#L42
--]]
local DEVICE_BUTTON_LOOKUP = {
  ['space']     = ' ',
  ['period']    = '.',
  ['comma']     = ',',
  ['backslash'] = '\\',
  ['tab']       = '\t',
  ['kp 0']      = '0',
  ['kp 1']      = '1',
  ['kp 2']      = '2',
  ['kp 3']      = '3',
  ['kp 4']      = '4',
  ['kp 5']      = '5',
  ['kp 6']      = '6',
  ['kp 7']      = '7',
  ['kp 8']      = '8',
  ['kp 9']      = '9',
  ['kp /']      = '/',
  ['kp *']      = '*',
  ['kp -']      = '-',
  ['kp +']      = '+',
  ['kp .']      = '.',
  ['kp =']      = '=',
}
local DEVICE_BUTTON_SHIFT_LOOKUP = {
  ['`']  = '~',
  ['1']  = '!',
  ['2']  = '@',
  ['3']  = '#',
  ['4']  = '$',
  ['5']  = '%',
  ['6']  = '^',
  ['7']  = '&',
  ['8']  = '*',
  ['9']  = '(',
  ['0']  = ')',
  ['-']  = '_',
  ['=']  = '+',
  ['[']  = '{',
  [']']  = '}',
  ['\''] = '"',
  ['\\'] = '|',
  [';']  = ':',
  [',']  = '<',
  ['.']  = '>',
  ['/']  = '?',
}
local function DeviceButtonToChar(button, useCurrentKeyModifiers) 
  local char
  
  if string.len(button) == 1 then
    local asciiByte = string.byte(button)
    if asciiByte > 31 and asciiByte < 127 then
      char = button
    end
  end
  
  if not char then
    char = DEVICE_BUTTON_LOOKUP[button:lower()]
  end
  
  if char and useCurrentKeyModifiers and isHoldingShift and not isHoldingCtrl then
    local shifted = DEVICE_BUTTON_SHIFT_LOOKUP[char]
    if shifted then
      char = shifted
    else
      char = char:upper()
    end
  end
  
  return char
end

local function Mixin(target, addon)
  for k, v in pairs(addon) do
    local vOriginal = target[k]
    if vOriginal ~= nil then
      target['_' .. k] = vOriginal
    end
    target[k] = v
  end
end

local function SetConstructor(target, ctor)
  return setmetatable(target, {
    __call = function(_, ...) return ctor(...) end
  })
end

local function GenerateLetterBox(properties)
	local t = Def.ActorFrame(properties or {})
	
	for keyY, row in ipairs(KEY_CHARACTER_MAP) do
		for keyX, character in ipairs(row) do
			local x, y, width = GetKeyProperties(keyX, keyY)
			x = x * GRID_CELL_WIDTH + GRID_CELL_WIDTH / 2 * width
			y = y * GRID_CELL_HEIGHT + GRID_CELL_HEIGHT / 2
			width = width * GRID_CELL_WIDTH
			local height = GRID_CELL_HEIGHT
			
			t[#t+1] = Def.ActorFrame{
				InitCommand=function(self)
					local c = self:GetChildren()
					
					local widthRatio = width/height
					if widthRatio >= 1.5 then						
						c.Sprite:Load(THEME:GetPathB('ScreenDDRNameEntry', 'overlay/endBOX'))
						c.Sprite:zoomx(widthRatio / 2)
					else
						c.Sprite:Load(THEME:GetPathB('ScreenDDRNameEntry', 'overlay/letterBOX'))
						c.Sprite:zoomx(widthRatio)
					end
					self:xy(x, y)
					
					if SPECIAL_CHARACTERS_LOOKUP[character] then
						c.Text:diffuse(Color.White):zoom(0.8)
					else
						c.Text:diffuse(color('#deff02')):zoom(1)
					end
					c.Text:settext(character)
				end,
				Def.Sprite{
					Name='Sprite',
				},
				Def.BitmapText{
					Name='Text',
					Font='_avenirnext lt pro bold/42px',
				},
			}
		end
	end
	return t
end

local function GenerateRecentNamesList(properties)
  local t = Def.ActorFrame(properties or {})
  local width = RECENT_NAMES_GRID_WIDTH * GRID_CELL_WIDTH
  local height = RECENT_NAMES_GRID_HEIGHT * GRID_CELL_HEIGHT
  
  for i = 1, MAX_RECENT_NAMES do
    local x = (i - 1) % RECENT_NAMES_COLS
    local y = math.floor((i - 1) / RECENT_NAMES_COLS)
		x = x * width + width / 2
    y = y * height + height / 2
    
    t[#t+1] = Def.ActorFrame{
      InitCommand=function(self)
        self:name('RecentName' .. i)
        local c = self:GetChildren()
        	
        local widthRatio = width/height
        c.Sprite:Load(THEME:GetPathB('ScreenDDRNameEntry', 'overlay/endBOX'))
        c.Sprite:zoomx(widthRatio / 2)
        self:xy(x, y)
        
        c.Text:diffuse(Color.White):zoom(0.8):maxwidth(width)
        c.Text:settext('##NAME' .. i .. '##') -- If we see these then something is wrong
      end,
      Def.Sprite{
        Name='Sprite',
      },
      Def.BitmapText{
        Name='Text',
        Font='_avenirnext lt pro bold/42px',
      },
    }
  end
  return t
end

local function CreateNameEntryFrame()
  local self = nil
  local function InputHandler(...)
    self:InputHandler(...)
  end
  
  return Def.ActorFrame{
    InitCommand=function(_self)
      local SelectionBoxFrame = _self:GetChild('SelectionBoxFrame')
      local LetterBoxFrame = SelectionBoxFrame:GetChild('LetterBoxFrame')
      
      -- We're just an sub-ActorFrame, the main ActorFrame is this actor's parent
      self = _self:GetParent()
      self.NameTextActor = _self:GetChild('NameText')
      self.SelectionBoxActor = SelectionBoxFrame:GetChild('SelectionBox')
      
      if self.ShowRecentNames then
        LetterBoxFrame:AddChild(function()
          return GenerateRecentNamesList{
            Name = 'RecentNamesFrame',
            InitCommand = function(_self2)
              _self2:y(GRID_ROWS * GRID_CELL_HEIGHT + RECENT_NAMES_MARGIN)
            end,
            Def.BitmapText{
              Name='RecentNamesHeader',
              Font='_avenirnext lt pro bold/20px',
              Text='RECENT DANCER NAMES:',
              InitCommand=function(_self2)
                _self2:align(0.5, 1):xy(GRID_COLS * GRID_CELL_WIDTH / 2, -2)
              end
            }
          }
        end)
        self.RecentNamesFrame = LetterBoxFrame:GetChild('RecentNamesFrame')
      end
      
      -- Mixin() might not have been ran yet, so call the NameEntry:CheckReady() method explicitly
      NameEntry.CheckReady(self)
    end,
    OnCommand=function()
      SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
    end,
    OffCommand=function()
      SCREENMAN:GetTopScreen():RemoveInputCallback(InputHandler)
    end,
    Def.ActorFrame{
      Name='SelectionBoxFrame',
      InitCommand=function(_self)
        -- local offsetX = -(KEY_COLS * GRID_CELL_WIDTH / 2)
        local offsetX = -(GRID_COLS * GRID_CELL_WIDTH / 2)
        local offsetY = -90
        _self:xy(offsetX, offsetY)
      end,
      Def.ActorFrame{ -- This ActorFrame is to ensure the SelectionBox is drawn over RecentNamesFrame
        Name='LetterBoxFrame',
        GenerateLetterBox(),
      },
      Def.Quad{
        Name='SelectionBox',
        InitCommand=function(_self)
          _self:diffuse(Alpha(Color.Red, 0.75)):blend(Blend.Add)
        end,
      },
    },
    Def.Sprite{
      Texture=THEME:GetPathB('ScreenDDRNameEntry', 'overlay/nameframe'),
      InitCommand=function(_self)
        _self:y(-120)
      end,
    },
    Def.BitmapText{
      Name='NameText',
      Font='DDRName Large',
      InitCommand=function(_self)
        _self:halign(1):xy(256, -120)
      end,
    },
  }
end

local function ValidateOptions(calleeName, opts)
  local player = opts.Player
  
  local invalidPlayer = true
  if player then
    for k, v in pairs(PlayerNumber) do
      if v == player then
        invalidPlayer = false
        break
      end
    end
  end
  if invalidPlayer then
    error(calleeName .. ': Player option is missing or invalid, got ' .. tostring(player) .. '!')
  end
end

-- NameEntry constructor
SetConstructor(NameEntry, function(opts)
  ValidateOptions('NameEntry()', opts)
  
  local t = Def.ActorFrame(opts)
  t[#t+1] = Def.Actor{
    InitCommand=function(self)
      -- We're just an Actor, the main ActorFrame is this actor's parent
      self = self:GetParent()
      Mixin(self, NameEntry)
      if type(self.Init) == 'function' then self:Init(opts) end
    end
  }
  t[#t+1] = CreateNameEntryFrame()
  return t
end)

local DefaultProperties = {
  DefaultName         = DEFAULT_NAME,
  Player              = false, -- This option is required
  AllowKeyboard       = false,
  AllowInputCallback  = true,
  EnterCallback       = false,
  ShowRecentNames     = true,
  FocusRecentNames    = false,
  KeyLeft             = 'MenuLeft',
  KeyRight            = 'MenuRight',
  KeyUp               = 'MenuUp',
  KeyDown             = 'MenuDown',
  KeyEnter            = 'Start',
}
function NameEntry:Init(opts)
  ValidateOptions('NameEntry:Init()', opts) -- In case opts got changed betweem constructor call and InitCommand
  
  for k, v in pairs(DefaultProperties) do
    local optsValue = opts[k] 
    if optsValue ~= nil then
      self[k] = optsValue
    else
      self[k] = v
    end
  end
  self.IsReady = false
  self:Reset()
  self:CheckReady()
end

function NameEntry:Reset()
  self.EnterPressed = false
  self.PlayerName = ''
  
  if self.ShowRecentNames and self.FocusRecentNames and #RecentNames > 0 then
    self.SelectionX = 1
    self.SelectionY = GRID_ROWS + 1
  else
    self.SelectionX = 1
    self.SelectionY = 1
  end
  if self.IsReady then
    self:Update()
  end
end

function NameEntry:CheckReady()
  -- This is set via Mixin() during InitCommand within the constructor
  if self.Init == nil then
    return false
  end
  -- These are set during InitCommand within CreateNameEntryFrame()
  if self.NameTextActor == nil
  or self.SelectionBoxActor == nil
  or (self.ShowRecentNames and self.RecentNamesFrame == nil) then
    return false
  end
  if self.IsReady then
    return false
  end
  self.IsReady = true
  self:Update()
  return true
end

function NameEntry:AssertReady(calleeName)
  if not self.IsReady then
    error('NameEntry:'..calleeName .. '(): Tried to execute when NameEntry is not ready!')
  end
end

function NameEntry:Update()
  self:AssertReady('Update')
  self.NameTextActor:settext(self.PlayerName)
  self:UpdateSelectionBox()
  
  if self.ShowRecentNames then
    local header = self.RecentNamesFrame:GetChild('RecentNamesHeader')
    header:visible(#RecentNames ~= 0)
    
    for i = 1, MAX_RECENT_NAMES do
      local name = RecentNames[i]
      local RecentName = self.RecentNamesFrame:GetChild('RecentName' .. i)
      if name then
        RecentName:visible(true)
        RecentName:GetChild('Text'):settext(name)
      else
        RecentName:visible(false)
      end
    end
  end
end

function NameEntry:RunCallback(callback, ...)
  if type(callback) == 'function' then
    return callback(self, ...)
  end
  return not not callback
end

function NameEntry:UpdateSelectionBox()
  self:AssertReady('UpdateSelectionBox')
  local keyX, keyY = GridXYToKeyXY(self.SelectionX, self.SelectionY)
  -- SCREENMAN:SystemMessage('GRID ' .. self.SelectionX .. ',' .. self.SelectionY .. ' = KEY ' .. keyX .. ',' .. keyY)
  local x, y, width, height = GetSelectionBoxProperties(keyX, keyY)
  self.SelectionBoxActor:xy(x, y):setsize(width, height)
end

function NameEntry:SelectEnterKey()
  self:AssertReady('SelectEnterKey')
  self.SelectionX = ENTER_KEY_POS.X
  self.SelectionY = ENTER_KEY_POS.Y
  self:UpdateSelectionBox()
end

function NameEntry:SetText(name)
  self:AssertReady('SetName')
  self.PlayerName = name
  self.NameTextActor:settext(self.PlayerName)
end

function NameEntry:NameAppend(char)
  self:AssertReady('NameAppend')
  local nameChanged = false
  char = ALLOWED_CHARACTERS_LOOKUP[char]
  if not char then return nameChanged end
  if string.len(self.PlayerName) < MAX_NAME_LENGTH then
    self.PlayerName = self.PlayerName .. char
    self.NameTextActor:settext(self.PlayerName)
    nameChanged = true
  end
  if string.len(self.PlayerName) == MAX_NAME_LENGTH then
    self:SelectEnterKey()
  end
  if nameChanged then
    SOUND:PlayOnce(THEME:GetPathS('Common', 'start'), true)
  end
  return nameChanged
end

function NameEntry:NameBackspace()
  self:AssertReady('NameBackspace')
  if string.len(self.PlayerName) <= 0 then return end
  self.PlayerName = string.sub(self.PlayerName, 1, -2)
  self.NameTextActor:settext(self.PlayerName)
  SOUND:PlayOnce(THEME:GetPathS('Common', 'start'), true)
end

function NameEntry:NameEnter(name)
  self:AssertReady('NameEnter')
  local params = {
    Player = self.Player,
    Name = self.PlayerName,
    IsDefaultName = false,
    IsRecentName = false,
    IsPresetName = false,
  }
  
  if name then
    params.IsRecentName = true
  elseif string.len(self.PlayerName) == 0 then
    params.IsDefaultName = true
    name = self.DefaultName
  end
  
  if name then
    params.IsPresetName = true
    params.Name = name
    self.PlayerName = name
    self.NameTextActor:settext(name)
  end
  
  local profile = PROFILEMAN:GetProfile(self.Player)
  profile:SetDisplayName(self.PlayerName) -- Will be used later to replace the Fill-In-Marker
  
  -- Makes GAMESTATE:AnyPlayerHasRankingFeats() work and allow the use of GAMESTATE:StoreRankingName(player, 'Name') to
  -- set the score's name after ScreenGameplay even when in event mode. See:
  -- https://github.com/stepmania/stepmania/blob/d55acb1ba26f1c5b5e3048d6d6c0bd116625216f/src/ProfileManager.cpp#L859
  -- https://github.com/stepmania/stepmania/blob/d55acb1ba26f1c5b5e3048d6d6c0bd116625216f/src/GameState.cpp#L2108
  local fillInMarker = PlayerNumberToRankingFillInMarker(self.Player)
  if fillInMarker then
    profile:SetLastUsedHighScoreName(fillInMarker)
  else
    profile:SetLastUsedHighScoreName('')
  end
  
  SOUND:PlayOnce(THEME:GetPathS('Common', 'start'), true)
  AddRecentName(self.PlayerName)
  self:RunCallback(self.EnterCallback, params)
  MESSAGEMAN:Broadcast('ProfileDisplayName'..ToEnumShortString(self.Player)..'Changed')
end

local PRESS_FIRST = 'FirstPress'
local PRESS_REPEAT = 'Repeat'
local PRESS_RELEASE = 'Release'

function NameEntry:InputHandler(event)
  self:AssertReady('InputHandler')
  UpdateKeyModifiers(event.DeviceInput)
  local pressType = ToEnumShortString(event.type)
	if not self:RunCallback(self.AllowInputCallback) then
    self.EnterPressed = false
    return
  end
  
  local gameButton = event.GameButton
  if gameButton and gameButton ~= '' then
    if event.PlayerNumber ~= self.Player then return end
    local SelectionX, SelectionY = self.SelectionX, self.SelectionY
    
    if gameButton == self.KeyEnter then
      local keyX, keyY = GridXYToKeyXY(SelectionX, SelectionY)
      if keyY <= KEY_ROWS then
        -- Letterbox
        local selection = KEY_CHARACTER_MAP[keyY][keyX]
        
        if selection == 'Enter' then
          if pressType == PRESS_FIRST then
            self.EnterPressed = true
          elseif pressType == PRESS_RELEASE then
            if self.EnterPressed then
              self:NameEnter()
            end
            self.EnterPressed = false
          end
        elseif selection == '←' and (pressType == PRESS_FIRST or pressType == PRESS_REPEAT) then
          self:NameBackspace()
        elseif pressType == PRESS_FIRST then
          self:NameAppend(selection)
        end
      else
        -- Recent names
        if pressType == PRESS_FIRST then
          self.EnterPressed = true
        elseif pressType == PRESS_RELEASE then
          if self.EnterPressed then
            local nameIndex = (keyY - KEY_ROWS - 1) * RECENT_NAMES_COLS + keyX
            local name = RecentNames[nameIndex]
            self:NameEnter(name)
          end
          self.EnterPressed = false
        end
      end
    else
      if not (pressType == PRESS_FIRST or pressType == PRESS_REPEAT) then return end
      local selectionChanged = false
      local deltaX, deltaY = 0, 0
      if     gameButton == self.KeyLeft  then deltaX = -1
      elseif gameButton == self.KeyRight then deltaX =  1
      elseif gameButton == self.KeyUp    then deltaY = -1 
      elseif gameButton == self.KeyDown  then deltaY =  1
      end
      
      if deltaX ~= 0 then
        local keyX, keyY = GridXYToKeyXY(SelectionX, SelectionY)
        keyX = keyX + deltaX
        
        if keyY <= KEY_ROWS then
          -- Navigating letterbox
          if keyX < 1 then
            SelectionY = wrap1(SelectionY - 1, GRID_ROWS)
            SelectionX = #GRID_TO_KEY_MAP[SelectionY]
          elseif keyX > #KEY_CHARACTER_MAP[SelectionY] then
            SelectionY = wrap1(SelectionY + 1, GRID_ROWS)
            SelectionX = 1
          else
            SelectionX = KEY_TO_GRID_MAP[keyY][keyX] + math.floor((KEY_WIDTH_MAP[keyY][keyX]-1)/2)
          end
        else
          -- Navigating recent names
          local nameRows = GetNumRecentNamesRows()
          if keyX < 1 then
            SelectionY = wrap1(SelectionY - GRID_ROWS - 1, nameRows) + GRID_ROWS
            keyX = GetNumRecentNamesCols(SelectionY - GRID_ROWS)
          elseif keyX > GetNumRecentNamesCols(SelectionY - GRID_ROWS) then
            if keyX > GetNumRecentNamesCols(1) then
              SelectionY = wrap1(SelectionY - GRID_ROWS + 1, nameRows) + GRID_ROWS
              keyX = 1
            else
              SelectionY = wrap1(SelectionY - GRID_ROWS - 1, nameRows) + GRID_ROWS
            end
          end
          SelectionX = 1 + math.floor((keyX - 1) * RECENT_NAMES_GRID_WIDTH + (RECENT_NAMES_GRID_WIDTH-1)/2)
        end
        selectionChanged = true
      end
      
      if deltaY ~= 0 then
        local numNamesRow = GetNumRecentNamesRows()
        
        -- Only switch between navigating within letterbox or recent names if the user tries to cross the boundary
        if SelectionY <= GRID_ROWS and deltaY < 0 then
          SelectionY = wrap1(SelectionY + deltaY, GRID_ROWS)
        elseif SelectionY > GRID_ROWS and deltaY > 0 and self.ShowRecentNames then
          SelectionY = wrap1(SelectionY + deltaY - GRID_ROWS, numNamesRow) + GRID_ROWS
        else
          local numTotalRows = GRID_ROWS
          if self.ShowRecentNames then
            numTotalRows = numTotalRows + numNamesRow
          end
          SelectionY = wrap1(SelectionY + deltaY, numTotalRows)
        end
        
        if SelectionY <= GRID_ROWS then
          -- Navigating letterbox
          while SelectionX > #GRID_TO_KEY_MAP[SelectionY] do -- We use GRID_TO_KEY_MAP to get num of grid columns per row
            SelectionY = wrap1(SelectionY + deltaY, GRID_ROWS)
          end
        else
          -- Navigating recent names
          local namesCols = GetNumRecentNamesCols(SelectionY - GRID_ROWS)
          if SelectionX > namesCols * RECENT_NAMES_GRID_WIDTH then
            SelectionX = 1 + math.floor((namesCols - 1) * RECENT_NAMES_GRID_WIDTH + (RECENT_NAMES_GRID_WIDTH-1)/2)
          end
        end
        selectionChanged = true
      end
      
      if selectionChanged then
        self.EnterPressed = false -- Disregard enter trigger if selection moved
        self.SelectionX, self.SelectionY = SelectionX, SelectionY
        self:UpdateSelectionBox()
        SOUND:PlayOnce(THEME:GetPathS('ScreenOptions', 'change'), true)
      end
    end
  elseif self.AllowKeyboard and ToEnumShortString(event.DeviceInput.device) == 'Key' then
    local button = ToEnumShortString(event.DeviceInput.button)
    local buttonLower = button:lower()
    
    -- In case the enter key isn't bound to a GameButton
    if buttonLower == 'enter' then
      if pressType == PRESS_FIRST then
        self.EnterPressed = true
      elseif pressType == PRESS_RELEASE then
        if self.EnterPressed then
          self:NameEnter()
        end
        self.EnterPressed = false
      end
    else
      self.EnterPressed = false -- Disregard enter trigger if another key pressed while enter is held down
    
      if buttonLower == 'backspace' and (pressType == PRESS_FIRST or pressType == PRESS_REPEAT)  then
        self:NameBackspace()
      elseif pressType == PRESS_FIRST then
        local char = DeviceButtonToChar(button, true)
        if not char then return end
        
        -- Some spacebar fallbacks in case space is not allowed
        if char == ' ' and not ALLOWED_CHARACTERS_LOOKUP[char] then
          if     ALLOWED_CHARACTERS_LOOKUP['_'] then char = '_'
          elseif ALLOWED_CHARACTERS_LOOKUP['-'] then char = '-'
          elseif ALLOWED_CHARACTERS_LOOKUP['.'] then char = '.'
          end
        end
        
        local nameChanged = self:NameAppend(char)
        
        -- If name was changed then move the cursor to the Enter key so we can easily
        -- complete the name entry if the enter key is bound to the Start GameButton.
        if nameChanged then
          self:SelectEnterKey()
        end
      end
    end
  end
  return true
end

local function CalculateTopAndBottomRecursively(self)
  local offset = self:GetY()
  local top, bottom = 0, 0
  
  if self.GetChildren then -- Is ActorFrame
    for name, children in pairs(self:GetChildren()) do
      -- Entries can be arrays due to conflicting names. To make it easier for ourselves lets make everything an array.
      if #children == 0 then
        children = { children }  -- if not an array then make it an array
      end
      for i, child in ipairs(children) do
        local _top, _bottom = CalculateTopAndBottomRecursively(child, p)
        top = math.min(top - offset, _top) + offset
        bottom = math.max(bottom - offset, _bottom) + offset
      end
    end
  elseif self.GetHeight then -- Is Actor with height
    local heightHalf = self:GetHeight() / 2
    top = offset - heightHalf
    bottom = offset + heightHalf
  end
  
  return top, bottom
end

-- Dirty hacky solution, but it works for now to let upstream center the NameEntry.
-- XXX: This will most likely fail if called this during InitCommand as NameEntry is not yet fully initialized!
--      Should we perhaps detect if it's called during InitCommand and warn about it?
function NameEntry:CalculateTopAndBottom()
  self:AssertReady('CalculateTopAndBottom')
  local top, bottom
  if self.CachedTopAndBottom then
    -- XXX: This will be wrong if upstream changes actors within the NameEntry frame. Lets hope they know what they're
    --      doing and will do NameEntry.CachedTopAndBottom = null to clear the cache before calling this function.
    top, bottom = self.CachedTopAndBottom[1], self.CachedTopAndBottom[2]
  else
    top, bottom = CalculateTopAndBottomRecursively(self)
    self.CachedTopAndBottom = { top, bottom }
  end
  if self.ShowRecentNames then
    local maxRecentNamesRows = math.ceil(MAX_RECENT_NAMES / RECENT_NAMES_COLS)
    local numRecentNamesRows = GetNumRecentNamesRows()
    bottom = bottom - (maxRecentNamesRows - numRecentNamesRows) * RECENT_NAMES_GRID_HEIGHT * GRID_CELL_HEIGHT
    if numRecentNamesRows == 0 then
      bottom = bottom - RECENT_NAMES_MARGIN
    end
  end
  return top, bottom
end

return NameEntry