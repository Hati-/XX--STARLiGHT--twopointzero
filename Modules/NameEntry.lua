local DEBUG = false

if StarlightCache and StarlightCache.NameEntry and not DEBUG then
  return StarlightCache.NameEntry
end

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

local function GridXYToKeyXY(gridX, gridY)
	if gridY < 1 or gridY > #GRID_TO_KEY_MAP then
		error('GridPosToKeySlot(x, y): y-value out of range. Got '..gridY..', but expects range [1, '..GRID_ROWS..']')
	end
	local keyXMap = GRID_TO_KEY_MAP[gridY]
	if gridX < 1 or gridX > #keyXMap then
		error('GridPosToKeySlot(x, y): x-value out of range. Got '..gridX..', but expects range [1, '..#keyXMap..']')
	end
	local keyX = keyXMap[gridX]
	local keyY = gridY
	return keyX, keyY
end

local function GetKeyProperties(keyX, keyY)
	if keyY < 1 or keyY > KEY_ROWS then
		error('GetKeyProperties(x, y): y-value out of range. Got '..keyY..', but expects range [1, '..KEY_ROWS..']')
	end
	local gridXMap = KEY_TO_GRID_MAP[keyY]
	if keyX < 1 or keyX > #gridXMap then
		error('GetKeyProperties(x, y): x-value out of range. Got '..keyX..', but expects range [1, '..#gridXMap..']')
	end
	local y = keyY - 1
	local x = gridXMap[keyX] - 1
	local width = KEY_WIDTH_MAP[keyY][keyX]
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

local function GenerateLetterBox()
	local t = Def.ActorFrame{}
	
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

local function CreateNameEntryFrame(self)
  local function InputHandler(...)
    self:InputHandler(...)
  end
  
  return Def.ActorFrame{
    InitCommand=function(_self)
      self.Frame = _self:GetParent() -- We're just a subframe, the actual main frame is this frame's parent
    end,
    OnCommand=function()
      if self.AllowKeyboard then
        SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)
      end
    end,
    OffCommand=function()
      SCREENMAN:GetTopScreen():RemoveInputCallback(InputHandler)
    end,
    CodeMessageCommand=function(_self, params)
      if params.PlayerNumber ~= self.Player then return end
      if not self:IsReady() then return end
      if not self:RunCallback(self.AllowInputCallback) then return end
      local SelectionX, SelectionY = self.SelectionX, self.SelectionY
      
      if params.Name == 'Start' then
        local keyX, keyY = GridXYToKeyXY(SelectionX, SelectionY)
        local selection = KEY_CHARACTER_MAP[keyY][keyX]
        if selection == 'Enter' then
          self:NameEnter()
        elseif selection == '←' then
          self:NameBackspace()
        else
          self:NameAppend(selection)
        end
      else
        local deltaX, deltaY = 0, 0
        if     params.Name == 'Left'  or params.Name == 'Left2'  then deltaX = -1
        elseif params.Name == 'Right' or params.Name == 'Right2' then deltaX =  1
        elseif params.Name == 'Up'    or params.Name == 'Up2'    then deltaY = -1 
        elseif params.Name == 'Down'  or params.Name == 'Down2'  then deltaY =  1
        end
        
        local selectionChanged = false
        if deltaX ~= 0 then
          local keyX, keyY = GridXYToKeyXY(SelectionX, SelectionY)
          keyX = keyX + deltaX
          
          if keyX < 1 then
            SelectionY = wrap1(SelectionY - 1, GRID_ROWS)
            SelectionX = #GRID_TO_KEY_MAP[SelectionY]
          elseif keyX > #KEY_CHARACTER_MAP[SelectionY] then
            SelectionY = wrap1(SelectionY + 1, GRID_ROWS)
            SelectionX = 1
          else
            SelectionX = KEY_TO_GRID_MAP[keyY][keyX] + math.floor((KEY_WIDTH_MAP[keyY][keyX]-1)/2)
          end
          selectionChanged = true
        end
        
        if deltaY ~= 0 then
          SelectionY = wrap1(SelectionY + deltaY, GRID_ROWS)
          while SelectionX > #GRID_TO_KEY_MAP[SelectionY] do -- We use GRID_TO_KEY_MAP to get num of grid columns per row
            SelectionY = wrap1(SelectionY + deltaY, GRID_ROWS)
          end
          selectionChanged = true
        end
        
        if selectionChanged then
          self.SelectionX, self.SelectionY = SelectionX, SelectionY
          self:UpdateSelectionBox()
          SOUND:PlayOnce(THEME:GetPathS('ScreenOptions', 'change'), true)
        end
      end
    end,
    Def.ActorFrame{
      InitCommand=function(_self)
        -- local offsetX = -(KEY_COLS * GRID_CELL_WIDTH / 2)
        local offsetX = -(GRID_COLS * GRID_CELL_WIDTH / 2)
        local offsetY = -90
        _self:xy(offsetX, offsetY)
      end,
      GenerateLetterBox(),
      Def.Quad{
        InitCommand=function(_self)
          self.SelectionBoxActor = _self
          _self:diffuse(Alpha(Color.Red, 0.75)):blend(Blend.Add)  
          self:UpdateSelectionBox()
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
      Font='DDRName Large',
      InitCommand=function(_self)
        self.NameTextActor = _self
        _self:halign(1):xy(256, -120)
      end,
    },
  }
end

local NameEntry = {}
NameEntry.__index = NameEntry

-- Constructor
function NameEntry:new(opts)
  local properties = {
    DefaultName = DEFAULT_NAME,
    Player = nil, -- This option is required
    AllowInputCallback = true,
    EnterCallback = false,
    AllowKeyboard = false,
  }
  for k, v in pairs(opts) do properties[k] = v end
  
  if not properties.Player or not GenerateRankingToFillInMarker(properties.Player) then
    error('NameEntry(): Player option is missing or invalid, got "' .. tostring(properties.Player) .. '"!')
  end
  properties.PlayerName = ''
  properties.SelectionX = 1
  properties.SelectionY = 1
  
  -- These are set during InitCommands
  properties.Frame = nil
  properties.NameTextActor = nil
  properties.SelectionBoxActor = nil
  
  local obj = setmetatable(Def.ActorFrame(properties), self)
  obj[#obj+1] = CreateNameEntryFrame(obj)
  return obj
end

function NameEntry:IsReady()
  return self.Frame ~= nil and self.NameTextActor ~= nil and self.SelectionBoxActor ~= nil
end

function NameEntry:RunCallback(callback)
  if type(callback) == 'function' then
    return callback(self.Frame)
  end
  return not not callback
end

function NameEntry:UpdateSelectionBox()
  local keyX, keyY = GridXYToKeyXY(self.SelectionX, self.SelectionY)
  local x, y, width, height = GetSelectionBoxProperties(keyX, keyY)
  self.SelectionBoxActor:xy(x, y):setsize(width, height)
end

function NameEntry:SelectEnterKey()
  self.SelectionX = ENTER_KEY_POS.X
  self.SelectionY = ENTER_KEY_POS.Y
  self:UpdateSelectionBox()
end

function NameEntry:NameAppend(char)
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
  if string.len(self.PlayerName) <= 0 then return end
  self.PlayerName = string.sub(self.PlayerName, 1, -2)
  self.NameTextActor:settext(self.PlayerName)
  SOUND:PlayOnce(THEME:GetPathS('Common', 'start'), true)
end

function NameEntry:NameEnter()
  if string.len(self.PlayerName) == 0 then
    self.PlayerName = self.DefaultName
    self.NameTextActor:settext(self.PlayerName)
  end
  local profile = PROFILEMAN:GetProfile(self.Player)
  profile:SetDisplayName(self.PlayerName) -- Will be used later to replace the Fill-In-Marker
  
  -- Makes GAMESTATE:AnyPlayerHasRankingFeats() work and allow the use of GAMESTATE:StoreRankingName(player, 'Name') to
  -- set the score's name after ScreenGameplay even when in event mode. See:
  -- https://github.com/stepmania/stepmania/blob/d55acb1ba26f1c5b5e3048d6d6c0bd116625216f/src/ProfileManager.cpp#L859
  -- https://github.com/stepmania/stepmania/blob/d55acb1ba26f1c5b5e3048d6d6c0bd116625216f/src/GameState.cpp#L2108
  local fillInMarker = GenerateRankingToFillInMarker(self.Player)
  if fillInMarker then
    profile:SetLastUsedHighScoreName(fillInMarker)
  else
    profile:SetLastUsedHighScoreName('')
  end
  
  SOUND:PlayOnce(THEME:GetPathS('Common', 'start'), true)
  
  self:RunCallback(self.EnterCallback)
end

function NameEntry:InputHandler(event)
  if not self:IsReady() then return end
	if not self:RunCallback(self.AllowInputCallback) then return end
  if event.GameButton and event.GameButton ~= '' then return end -- Don't do anything if input is mapped to a GameButton
  if ToEnumShortString(event.type) ~= 'FirstPress' then return end
  if ToEnumShortString(event.DeviceInput.device) ~= 'Key' then return end -- Only allow keyboard input
  local key = ToEnumShortString(event.DeviceInput.button):lower()
	
	if key == 'backspace' then
		self:NameBackspace()
	elseif key == 'enter' then -- In case the enter key isn't bound to a GameButton
		self:NameEnter()
	else
		if self:NameAppend(key) then
			-- Move to Enter key so we can easily complete the name entry if the enter key is bound to the Start GameButton
			self:SelectEnterKey()
		end
	end
end
	
return function(...)
  return NameEntry:new(...)
end