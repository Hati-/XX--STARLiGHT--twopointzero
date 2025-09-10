local player = ...
local defaultName = 'STARLGHT'

local name = ''
setenv('keysetSDDRN' .. ToEnumShortString(player), 0)

local MAX_NAME_LENGTH = 8
local SELECTION_X, SELECTION_Y = 1, 1
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
-- KEY_WIDTH_MAP[3][4] = 3 -- X (for testing)
-- KEY_WIDTH_MAP[2][2] = 2 -- L (for testing)

-- Lookup tables
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
local ALLOWED_CHARACTERS_LOOKUP = {}
for keyY, row in ipairs(KEY_CHARACTER_MAP) do
	for keyX, character in ipairs(row) do
		if not SPECIAL_CHARACTERS_LOOKUP[character] then
			ALLOWED_CHARACTERS_LOOKUP[character:lower()] = character
			ALLOWED_CHARACTERS_LOOKUP[character:upper()] = character
		end
	end
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

local function GenerateLetterBox()
	local f = Def.ActorFrame{}
	
	for keyY, row in ipairs(KEY_CHARACTER_MAP) do
		for keyX, character in ipairs(row) do
			local x, y, width = GetKeyProperties(keyX, keyY)
			x = x * GRID_CELL_WIDTH + GRID_CELL_WIDTH / 2 * width
			y = y * GRID_CELL_HEIGHT + GRID_CELL_HEIGHT / 2
			width = width * GRID_CELL_WIDTH
			local height = GRID_CELL_HEIGHT
			
			f[#f+1] = Def.ActorFrame{
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
	return f
end

function GetSelectionBoxProperties(keyX, keyY)
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

-- These are set during InitCommands
local NameTextActor
local SelectionBoxActor

local function UpdateSelectionBox()
		local keyX, keyY = GridXYToKeyXY(SELECTION_X, SELECTION_Y)
		local x, y, width, height = GetSelectionBoxProperties(keyX, keyY)
		SelectionBoxActor:xy(x, y):setsize(width, height)
end

local function NameAppend(char)
	local nameChanged = false
	char = ALLOWED_CHARACTERS_LOOKUP[char]
	if not char then return nameChanged end
	if string.len(name) < MAX_NAME_LENGTH then
		name = name .. char
		NameTextActor:settext(name)
		nameChanged = true
	end
	if string.len(name) == MAX_NAME_LENGTH then
		-- Move to Enter key
		SELECTION_X = 9
		SELECTION_Y = 5
		UpdateSelectionBox()
	end
	if nameChanged then
		SOUND:PlayOnce(THEME:GetPathS('Common', 'start'), true)
	end
	return nameChanged
end

local function NameBackspace()
	if string.len(name) <= 0 then return end
	name = string.sub(name, 1, -2)
	NameTextActor:settext(name)
	SOUND:PlayOnce(THEME:GetPathS('Common', 'start'), true)
end

local function NameEnter()
	if string.len(name) == 0 then
		name = defaultName
	end
	local profile = PROFILEMAN:GetProfile(player)
	profile:SetDisplayName(name) -- Will be used later to replace the Fill-In-Marker
	
	-- Makes GAMESTATE:AnyPlayerHasRankingFeats() work and allow the use of GAMESTATE:StoreRankingName(player, 'Name') to
	-- set the score's name after ScreenGameplay even when in event mode. See:
	-- https://github.com/stepmania/stepmania/blob/d55acb1ba26f1c5b5e3048d6d6c0bd116625216f/src/ProfileManager.cpp#L859
	-- https://github.com/stepmania/stepmania/blob/d55acb1ba26f1c5b5e3048d6d6c0bd116625216f/src/GameState.cpp#L2108
	local fillInMarker = GenerateRankingToFillInMarker(player)
	if fillInMarker then
		profile:SetLastUsedHighScoreName(fillInMarker)
	else
		profile:SetLastUsedHighScoreName('')
	end
	
	setenv('keysetSDDRN' .. ToEnumShortString(player), 1)
	if GAMESTATE:GetNumPlayersEnabled() == 1 or (getenv('keysetSDDRNP1') == 1 and getenv('keysetSDDRNP2') == 1) then
		SCREENMAN:GetTopScreen():StartTransitioningScreen('SM_GoToNextScreen')
	end
	
	SOUND:PlayOnce(THEME:GetPathS('Common', 'start'), true)
end

local function Player1InputHandler(event)
	if event.GameButton and event.GameButton ~= '' then return end -- Don't do anything if input is mapped to a GameButton
	if ToEnumShortString(event.type) ~= 'FirstPress' then return end
	if ToEnumShortString(event.DeviceInput.device) ~= 'Key' then return end -- Only allow keyboard input
	local key = ToEnumShortString(event.DeviceInput.button):lower()
	
	if key == 'backspace' then
		NameBackspace()
	elseif key == 'enter' then -- In case the enter key isn't bound to a GameButton
		NameEnter()
	else
		if NameAppend(key) then
			-- Move to Enter key so we can easily complete the name entry if the enter key is bound to the Start GameButton
			SELECTION_X = 9
			SELECTION_Y = 5
			UpdateSelectionBox()
		end
	end
end

local t = Def.ActorFrame{
	OnCommand=function(self)
		if player == PLAYER_1 then
			SCREENMAN:GetTopScreen():AddInputCallback(Player1InputHandler)
		end
	end,
	OffCommand=function(self)
		SCREENMAN:GetTopScreen():RemoveInputCallback(Player1InputHandler)
	end,
	Def.ActorFrame{
		Name='Panes',
		Def.ActorFrame{
			InitCommand=function(self)
				self:shadowlength(0):zoomy(0)
			end,
			OnCommand=function(self)
				self:sleep(0.3):linear(0.3):zoomy(1)
			end,
			OffCommand=function(self)
				self:linear(0.1):zoomy(0)
			end,
			Def.Sprite{
				Texture=THEME:GetPathG('', 'ScreenSelectProfile/BG01'),
			},
			Def.Quad{
				InitCommand=function(self)
					self:setsize(512, 440):y(-20):diffuse(Alpha(Color.Black, 0.75))
				end,
			},
		},
		Def.ActorFrame{
			InitCommand=function(self)
				self:y(-292)
			end,
			OnCommand=function(self)
				self:y(0):sleep(0.3):linear(0.3):y(-292)
			end,
			OffCommand=function(self)
				self:linear(0.1):y(0):sleep(0):diffusealpha(0)
			end,
			Def.Sprite{
				Texture=THEME:GetPathG('', 'ScreenSelectProfile/BGTOP_' .. ToEnumShortString(player)),
				InitCommand=function(s) s:valign(1) end,
			},
		},
		Def.ActorFrame{
			Name='Bottom',
			InitCommand=function(self)
			  self:shadowlength(0)
			end,
			OnCommand=function(self)
				self:y(0):sleep(0.3):linear(0.3):y(286)
			end,
			OffCommand=function(self)
				self:linear(0.1):y(0):sleep(0):diffusealpha(0)
			end,
			Def.Sprite{
				Texture=THEME:GetPathG('', 'ScreenSelectProfile/BGBOTTOM'),
				InitCommand=function(s) s:valign(0) end,
			},
			Def.Sprite{
				Texture=THEME:GetPathG('', 'ScreenSelectProfile/start game'),
			  	InitCommand=function(s) s:valign(0):diffusealpha(0) end,
			  	OnCommand=function(s) s:sleep(0.8):diffusealpha(1) end,
			},
		},
	},
	Def.ActorFrame{
		InitCommand=function(self)
			self:hibernate(0.6)
		end,
		OffCommand=function(self)
			self:diffusealpha(0)
		end,
		Def.ActorFrame{
			InitCommand=function(self)
				-- local offsetX = -(KEY_COLS * GRID_CELL_WIDTH / 2)
				local offsetX = -(GRID_COLS * GRID_CELL_WIDTH / 2)
				local offsetY = -90
				self:xy(offsetX, offsetY)
			end,
			GenerateLetterBox(),
			Def.Quad{
				InitCommand=function(self)
					SelectionBoxActor = self
					local keyX, keyY = GridXYToKeyXY(SELECTION_X, SELECTION_Y)
					local x, y, width, height = GetSelectionBoxProperties(keyX, keyY)
					self:diffuse(Alpha(Color.Red, 0.75)):blend(Blend.Add):xy(x, y):setsize(width, height)
				end,
				CodeMessageCommand=function(self, params)
					if params.PlayerNumber ~= player then return end
					if getenv('SDDRNJoined' .. player) ~= 1 then return end
					
					if params.Name == 'Start' then
						local keyX, keyY = GridXYToKeyXY(SELECTION_X, SELECTION_Y)
						local selection = KEY_CHARACTER_MAP[keyY][keyX]
						if selection == 'Enter' then
							NameEnter()
						elseif selection == '←' then
							NameBackspace()
						else
							NameAppend(selection)
						end
					else
						local deltaX = 0
						local deltaY = 0
						if params.Name == 'Left' or params.Name == 'Left2' then
							deltaX = -1
						elseif params.Name == 'Right' or params.Name == 'Right2' then
							deltaX =  1
						elseif params.Name == 'Up' or params.Name == 'Up2' then
							deltaY = -1 
						elseif params.Name == 'Down' or params.Name == 'Down2' then
							deltaY =  1
						end
						if deltaX ~= 0 then
							local keyX, keyY = GridXYToKeyXY(SELECTION_X, SELECTION_Y)
							keyX = keyX + deltaX
							
							if keyX < 1 then
								SELECTION_Y = wrap1(SELECTION_Y - 1, GRID_ROWS)
								SELECTION_X = #GRID_TO_KEY_MAP[SELECTION_Y]
							elseif keyX > #KEY_CHARACTER_MAP[SELECTION_Y] then
								SELECTION_Y = wrap1(SELECTION_Y + 1, GRID_ROWS)
								SELECTION_X = 1
							else
								SELECTION_X = KEY_TO_GRID_MAP[keyY][keyX] + math.floor((KEY_WIDTH_MAP[keyY][keyX]-1)/2)
							end
							
							UpdateSelectionBox()
							SOUND:PlayOnce(THEME:GetPathS('ScreenOptions', 'change'), true)
						end
						
						if deltaY ~= 0 then
							SELECTION_Y = wrap1(SELECTION_Y + deltaY, GRID_ROWS)
							while SELECTION_X > #GRID_TO_KEY_MAP[SELECTION_Y] do -- We use GRID_TO_KEY_MAP to get grid columns per row
								SELECTION_Y = wrap1(SELECTION_Y + deltaY, GRID_ROWS)
							end
							
							UpdateSelectionBox()
							SOUND:PlayOnce(THEME:GetPathS('ScreenOptions', 'change'), true)
						end
					end
				end
			},
		},
		Def.BitmapText{
			Font='_avenirnext lt pro bold/36px',
			InitCommand=function(self)
				self:xy(-250, -190):halign(0):zoom(0.9):strokecolor(Color.Black)
			end,
			Text='Register a DANCER NAME.\nEnter the name you want to use.',
		},
		Def.Sprite{
			Texture='nameframe',
			InitCommand=function(self)
				self:y(-120)
			end,
		},
		Def.BitmapText{
			Font='DDRName Large',
			Name='NameActor',
			InitCommand=function(self)
				NameTextActor = self
				self:halign(1):xy(256, -120)
			end,
		},
	}
}
	
return t