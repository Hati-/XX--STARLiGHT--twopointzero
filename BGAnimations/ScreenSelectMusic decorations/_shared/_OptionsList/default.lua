local IsMenuOpen = { PlayerNumber_P1 = false, PlayerNumber_P2 = false}
local CurrentClosingPlayer -- Global hack for race condition when exiting with the Select button...
local MenuButtonsOnly = PREFSMAN:GetPreference("OnlyDedicatedMenuButtons")

local t= Def.ActorFrame{
    Def.Sound{
        File=THEME:GetPathS("","Codebox/o-change"),
        OptionsListRightMessageCommand=function(s) s:play() end,
        OptionsListLeftMessageCommand=function(s) s:play() end,
        OptionsListPushMessageCommand=function(s) s:play() end,
        OptionsListPopMessageCommand=function(s) s:play() end,
        OptionsListResetMessageCommand=function(s) s:play() end,
        OptionsListStartMessageCommand=function(s) s:play() end,
    };
    Def.Sound{
        File=THEME:GetPathS("","Codebox/o-open"),
        OptionsListOpenedMessageCommand=function(s)
            setenv("OPList",1)
            s:play()
        end,
    };
    Def.Sound{
        File=THEME:GetPathS("","Codebox/o-close"),
        OptionsListClosedMessageCommand=function(s) s:play()
            setenv("OPList",0)
            if getenv("DList") == 1 and not ShowTwoPart() then
                SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_MenuTimer")
            end
            ProfilePrefs.SaveAll()
        end,
    };
}

local OPTIONSLIST_NUMNOTESKINS = (ThemePrefs.Get("ExclusiveNS") == true and #GetXXSkins() ~= 0) and #GetXXSkins() or #NOTESKIN:GetNoteSkinNames()
local OPTIONSLIST_NOTESKINS = (ThemePrefs.Get("ExclusiveNS") == true and #GetXXSkins() ~= 0) and GetXXSkins() or NOTESKIN:GetNoteSkinNames()

local song_bpms= {}
local bpm_text= "??? - ???"
local function format_bpm(bpm)
	return ("%.0f"):format(bpm)
end

local fixedNS = OPTIONSLIST_NOTESKINS
table.insert(fixedNS,"EXIT")


-- local fixedChar = Characters.GetAllCharacterNames()
-- if #fixedChar > 1 then
--     table.insert(fixedChar, 1, "OFF")
--     if SN3Debug then SCREENMAN:SystemMessage("Found "..#fixedChar.." characters!") end
--     table.insert(fixedChar, 2, "RANDOM")
-- else
--     --if SN3Debug then SCREENMAN:SystemMessage("Found no characters! :<") end
-- end
-- table.insert(fixedChar, "EXIT")
local fixedChar = GetAllCharacterNames()
table.insert(fixedChar,#fixedChar+1,"OKAY")
local DanceStagesList = GetAllDanceStagesNames()
table.insert(DanceStagesList,#DanceStagesList+1,"OKAY")

local NumMini = fornumrange(-100,100,5)
table.insert(NumMini, "EXIT")

local NumRate = fornumrange(10,200,5)
table.insert(NumRate,"EXIT")

local _CHAR, _DS, _NSKIN, _MINI, _RATE = {},{},{},{},{};


for i=1,#fixedChar do
    local CurrentCharacter = fixedChar[i];
    _CHAR[i] = Def.ActorFrame{
        Def.Sprite{
            Texture="cards/BAR.png",
            InitCommand=function(s) s:zoom(0.6):y(-220+12) end,
        };
        Def.BitmapText{
            Font="_avenirnext lt pro bold/46px",
            Text=CurrentCharacter,
            InitCommand=function(s) s:zoom(0.9):addy(30) end,
        }
    }
end
for i=1,#DanceStagesList do
    local CurrentStage = DanceStagesList[i];
    _DS[i] = Def.ActorFrame{
        Def.Sprite{
            Texture="cards/BAR.png",
            InitCommand=function(s) s:zoom(0.6):y(-220+12) end,
        };
        Def.BitmapText{
            Font="_avenirnext lt pro bold/46px",
            Text=CurrentStage,
            InitCommand=function(s) s:zoom(0.7):addy(33) end,
        }
    }
end
for i=1,#fixedNS do
    local CurrentSkin = fixedNS[i];
    _NSKIN[i] = LoadModule("NoteskinObjLoad.lua",{NoteSkin = CurrentSkin, Player = GAMESTATE:GetMasterPlayerNumber()})
end;
for i=1,#NumMini do
    local CurrentMini = NumMini[i];
    _MINI[i] = Def.ActorFrame{
        Def.Sprite{
            Texture="optionIcon",
            InitCommand=function(s) s:zoom(1.5) end,
        };
        Def.BitmapText{
            Font="_avenirnext lt pro bold/20px",
            InitCommand=function(s) s:zoom(1.5)
                if CurrentMini ~= "EXIT" then
                    s:settext(CurrentMini.."%")
                else
                    s:settext("EXIT")
                end
            end,
        };
    }
end;

for i=1,#NumRate do
    local CurrentRate = NumRate[i];
    _RATE[i] = Def.ActorFrame{
        Def.Sprite{
            Texture="optionIcon",
            InitCommand=function(s) s:zoom(1.5) end,
        };
        Def.BitmapText{
            Font="_avenirnext lt pro bold/20px",
            InitCommand=function(s) s:zoom(1.5)
                if CurrentRate ~= "EXIT" then
                    s:settext(CurrentRate.."%")
                else
                    s:settext("EXIT")
                end
            end,
        };
    }
end;

local function CurrentNoteSkin(p)
    local state = GAMESTATE:GetPlayerState(p)
    local mods = state:GetPlayerOptionsArray( 'ModsLevel_Preferred' )
    local skins = NOTESKIN:GetNoteSkinNames()

    for i = 1, #mods do
        for j = 1, #skins do
            if string.lower( mods[i] ) == string.lower( skins[j] ) then
               return skins[j];
            end
        end
    end
end
--I really ought to just make these unified.
local function CurrentMiniVal(p)
    local nearest_i
    local best_difference = math.huge
    for i,v2 in ipairs(stringify(fornumrange(-100,100,5), "%g%%")) do
        local mini = GAMESTATE:GetPlayerState(p):GetPlayerOptions("ModsLevel_Preferred"):Mini()
        local this_diff = math.abs(mini - v2:gsub("(%d+)%%", tonumber) / 100)
        if this_diff < best_difference then
            best_difference = this_diff
            nearest_i = i
        end
    end
    return NumMini[nearest_i]
end

local function CurrentRateVal(p)
    local nearest_i
    local best_difference = math.huge
    for i,v2 in ipairs(stringify(fornumrange(10,200,5), "%g%%")) do
        local rate = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate()
        local this_diff = math.abs(rate - v2:gsub("(%d+)%%", tonumber) / 100)
        if this_diff < best_difference then
            best_difference = this_diff
            nearest_i = i
        end
    end
    return NumRate[nearest_i]
end

local function GetRateIndex(Rate)
    local index={}
    for k,v in pairs(NumRate) do
        index[v] = k
    end
    return index[Rate]
end
    

local function GetCNSIndex(CNS)
    local index={}
    for k,v in pairs(OPTIONSLIST_NOTESKINS) do
        index[v] = k
    end
    return index[CNS]
end

local function GetCharIndex(Char)
    local index={}
    for k,v in pairs(fixedChar) do
        index[v] = k
    end
    return index[Char]
end

local function GetMiniIndex(Mini)
    local index={}
    for k,v in pairs(NumMini) do
        index[v] = k
    end
    return index[Mini]
end

local function getSelectionImage(key, getAssetPath, specialKeyImages)
    local image
    for specialKey, specialImage in pairs(specialKeyImages) do
        if not (specialKey == '_UNKNOWN' or key == '_OKAY') then
            if key == specialKey then
                image = specialImage
                break
            end
        end
    end
    if not image then
        local assetImage = getAssetPath(key, true)
        local assetData = getAssetPath(key)
        if FILEMAN:DoesFileExist(assetImage) then -- If has card image
            assert(FILEMAN:DoesFileExist(assetData))
            image = assetImage
        elseif FILEMAN:DoesFileExist(assetData) then -- If missing card image but has asset data
            image = specialKeyImages._UNKNOWN
        end
    end
    assert(image)
    return image
end

local function getUserPrefKeyFunc(prefName)
    if prefName == 'Characters' then
        return function(pn) return ResolveCharacterName(pn) end
    end
    return function(pn) return GetUserPref(prefName) end
end

local SelectionTable = {
    Characters = {
        getAssetPath = function(name, isImg)
            return '/Characters/' ..name.. (isImg and '/Card.png' or '/Model.txt')
        end,
        specialKeyImages = {
            _UNKNOWN = THEME:GetPathB("ScreenSelectMusic", "decorations/_shared/_OptionsList/cards/Unknown.png"),
            _OKAY    = THEME:GetPathB("ScreenSelectMusic", "decorations/_shared/_OptionsList/cards/Okay.png"),
            Random   = THEME:GetPathB("ScreenSelectMusic", "decorations/_shared/_OptionsList/cards/Random.png"),
        }
    },
    DanceStages = {
        getAssetPath = function(name, isImg)
            return '/DanceStages/' ..name.. (isImg and '/Card.png' or '/LoaderA.lua')
        end,
        specialKeyImages = {
            _UNKNOWN = THEME:GetPathB("ScreenSelectMusic", "decorations/_shared/_OptionsList/cards/DSU.png"),
            _OKAY    = THEME:GetPathB("ScreenSelectMusic", "decorations/_shared/_OptionsList/cards/DSO.png"),
            RANDOM   = THEME:GetPathB("ScreenSelectMusic", "decorations/_shared/_OptionsList/cards/DSR.png"),
            DEFAULT  = THEME:GetPathB("ScreenSelectMusic", "decorations/_shared/_OptionsList/cards/DSAC.png"),
        }
    }
}

for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
    local OptionsListActor, OptionsListMenu
    local numRows
    
    -- I would have this outside the for-loop, but it's too tightly coupled with pn, OptionsListActor, and OptionsListMenu
    local function createSelectionScroller(menuName, actors, keys, getUserPrefKey, getAssetPath, specialKeyImages)
        return Def.ActorFrame{
            InitCommand=function(self) 
                self:y(-200):zoom(1):diffusealpha(0) 
            end,
            OptionsMenuChangedMessageCommand=function(self,params)
                if params.Player == pn then
                    if params.Menu == menuName then
                        self:playcommand("On")
                        self:stoptweening():linear(.3):diffusealpha(1);
                    else
                        self:diffusealpha(0);
                    end;
                end;
            end;

            Def.Sprite{
                Name="Sprite",
                InitCommand=function(self)
                    self:xy(240,220-20):diffusealpha(0):halign(0.985):zoom(0.6)
                end,
                OnCommand=function(self)
                    local key = getUserPrefKey(pn)
                    local image = getSelectionImage(key, getAssetPath, specialKeyImages)
                    self:Load(image)
                end,
                OptionsMenuChangedMessageCommand=function(self,params)
                    local selectedKey = getUserPrefKey(pn)
                    if params.Player == pn then
                        if selectedKey ~= "" then
                            self:queuecommand("On")
                            self:stoptweening():linear(.3);
                            self:diffusealpha(1);
                        else
                            self:diffusealpha(1);
                        end;
                    end;
                end,
                AdjustCommand=function(self,params)
                    if params.Player == pn and OptionsListMenu == menuName then
                        if params.Selection < (#keys-1) and params.Selection > -1 then
                            self:diffusealpha(1)
                            local key = keys[params.Selection+1]
                            local image = getSelectionImage(key, getAssetPath, specialKeyImages)
                            self:stoptweening():linear(.3);
                            self:Load(image)
                            self:diffusealpha(1)
                        else
                            self:Load(specialKeyImages._OKAY)
                            self:diffusealpha(1)
                        end
                    end
                end,
            };
            Def.ActorScroller{
                Name="Scroller",
                NumItemsToDraw=1;
                SecondsPerItem=1/200;
                children = actors;
                InitCommand=function(self)
                    self:y(410):zoom(1)
                    self:SetLoop(false):SetWrap(true)
                    :SetDrawByZPosition(true):SetFastCatchup(true)
                end,
                OptionsMenuChangedMessageCommand=function(self,params)
                    if params.Player == pn then
                        local index = IndexKey(keys, getUserPrefKey(pn))
                        if index ~= nil then
                            self:SetCurrentAndDestinationItem(index-1)
                        else
                            self:SetCurrentAndDestinationItem(0)
                        end
                    end;
                end;
                TransformFunction=function(self, offset, itemIndex, numItems)
                    -- self:x(100 * offset)
                    local sign = offset == 0 and 1 or offset/math.abs(offset)
                    self:x((offset*240*math.cos((math.pi/6*offset))+math.min(math.abs(offset),1)*sign*0))
                    :z((offset*-62*3*math.sin((math.pi/6)*offset))+(math.min(math.abs(offset),1)*0))
                    :rotationy(offset*(360/(6*1.135)))
                    
                end,
                AdjustCommand=function(self,params)
                    if params.Player == pn and OptionsListMenu == menuName then
                        self:SetDestinationItem(params.Selection)
                    end
                end,
            };

            Def.Sprite{
                Texture="arrow",
                InitCommand=function(self) self:xy(-280,230-20):zoom(2):diffusealpha(1):bounce():effectmagnitude(3,0,0):effectperiod(1) end,
                OptionsListLeftMessageCommand=function(self) self:finishtweening():diffuse(color("#8080ff")):sleep(0.3):linear(0.4):diffuse(color("1,1,1,1")) end,
            };

            Def.Sprite{
                Texture="arrow",
                InitCommand=function(self) self:xy(280,230-20):basezoom(2):zoomx(-1):diffusealpha(1):bounce():effectmagnitude(-3,0,0):effectperiod(1) end,
                OptionsListRightMessageCommand=function(self) self:finishtweening():diffuse(color("#8080ff")):sleep(0.3):linear(0.4):diffuse(color("1,1,1,1")) end,
            };
        };
    end
    
    --if (string.find(ProductVersion(), "LTS")) then
        --if SN3Debug then
        --    SCREENMAN:SystemMessage("LTS or below detected! Changing OptionsList actor call!")
        --end
        t[#t+1] = Def.ActorFrame{
            Def.Actor{
                Name="OptionsList" .. pname(pn),
                CodeMessageCommand=function(self, params)
                    if ((params.Name == "OpenOpList" and not MenuButtonsOnly) or
                        params.Name == "OpenOpListButton") and params.PlayerNumber == pn and not IsMenuOpen[pn] then
                        SCREENMAN:GetTopScreen():OpenOptionsList(params.PlayerNumber)
                        MESSAGEMAN:Broadcast("OptionsListPlaySound")
                    end
             end
            },
        }
    --[[else
        if SN3Debug then
            SCREENMAN:SystemMessage("AlphaV or above detected! Changing OptionsList actor call! Version: "..string.sub(ProductVersion(),1,3))
        end
        t[#t+1] = Def.ActorFrame{
            Def.OptionsList {
                Name="OptionsList" .. pname(pn),
                Player=pn,
                InitCommand=function(s) s:ztestmode('ZTestMode_WriteOnPass'):MaskDest() end,
                CodeMessageCommand=function(self, params)
                    if ((params.Name == "OpenOpList" and not MenuButtonsOnly) or
                        params.Name == "OpenOpListButton") and params.PlayerNumber == pn and not IsMenuOpen[pn] then
                        self:Open()
                        MESSAGEMAN:Broadcast("OptionsListPlaySound")
                    end
                end
            },
        }
    end]]

    t[#t+1] = Def.ActorFrame{
        InitCommand=function(s)
            s:x(
                pn==PLAYER_1 and (IsUsingWideScreen() and _screen.cx-566 or _screen.cx-360) or
                (IsUsingWideScreen() and _screen.cx+566 or _screen.cx+360)
            )
            :y(SCREEN_BOTTOM+700):zoom(0.8)
        end,
        OnCommand=function(self)
            OptionsListActor = SCREENMAN:GetTopScreen():GetChild("OptionsList"..pname(pn))
        end,
        OptionsListOpenedMessageCommand=function(s,p)
            if p.Player == pn then
                IsMenuOpen[pn] = true
                s:decelerate(0.2):y(_screen.cy)
            end
        end,
        OptionsListClosedMessageCommand=function(self, params)
            if params.Player == pn then
                CurrentClosingPlayer = pn
                self:stoptweening():accelerate(0.2):y(SCREEN_BOTTOM+700)
                self:queuecommand("ClosedMenu")
            end
        end,
        ClosedMenuCommand=function(self)
            IsMenuOpen[CurrentClosingPlayer] = false
        end,

        -- Make us able to view what menu we're in later (and also adjust its position)
        OptionsMenuChangedMessageCommand=function(self, params)
            if params.Player == pn then
                OptionsListMenu = params.Menu
                numRows = tonumber(THEME:GetMetric("ScreenOptionsMaster", OptionsListMenu))
                if OptionsListMenu ~= "SongMenu" and OptionsListMenu ~= "AdvMenu" and OptionsListMenu ~= "RemMenu" then
                    if OptionsListMenu == "NoteSkins"
                    or OptionsListMenu == "Characters"
                    or OptionsListMenu == "DanceStage"
                    or OptionsListMenu == "Mate1"
                    or OptionsListMenu == "Mate2"
                    or OptionsListMenu == "Mate3"
                    or OptionsListMenu == "Mate4"
                    or OptionsListMenu == "Mate5"
                    or OptionsListMenu == "Mate6"
                    or OptionsListMenu == "Mini"
                    or OptionsListMenu == "MusicRate" then
                        OptionsListActor:stoptweening():diffusealpha(0)
                    else
                        OptionsListActor:stoptweening():diffusealpha(1)
                    end
                else
                    --SCREENMAN:SystemMessage(params.Size);
                    OptionsListActor:stoptweening():diffusealpha(1)
                end

                self:playcommand("Adjust", params)
            end
        end,

        OptionsListLeftMessageCommand=function(self, params) self:playcommand("Adjust", params) end,
        OptionsListRightMessageCommand=function(self, params) self:playcommand("Adjust", params) end,
        OptionsListStartMessageCommand=function(self, params) self:playcommand("Adjust", params) end,
        
        -- If we're doing START+LEFT or START+RIGHT to change a setting without entering the setting's submenu then
        -- OptionsListMenu and params.Selection is wrong. Don't run AdjustCommand on this ActorFrame if that's the case. 
        OptionsListQuickChangeMessageCommand=function(self, params) params.Type = 'OptionsListQuickChange'; self:playcommand("Adjust", params) end,

        -- To avoid overflowing the list, we will hide the outer parts and
        -- dynamically move the entire list's vertical position relative
        -- to what the player is currently selecting
        AdjustCommand=function(self, params)
            if params.Type == 'OptionsListQuickChange' then
                return
            end
            
            if params.Player == pn then
                local base_y = 350

                -- Handle scrolling in different options menus
                if OptionsListMenu == "CharaDS" then
                    OptionsListActor:stoptweening():y(base_y + 305)
                elseif OptionsListMenu == "DMates" then
                    OptionsListActor:stoptweening():y(base_y + 60)
                elseif OptionsListMenu == "NoteSkins" and params.Selection + 1 > 5 then
                    OptionsListActor:stoptweening():linear(0.1):y(base_y - (22 * (params.Selection - 5)))
                elseif params.Selection + 1 > 9 then
                    OptionsListActor:stoptweening():linear(0.1):y(base_y - (22 * (params.Selection - 7)))
                else
                    OptionsListActor:stoptweening():linear(0.1):y(base_y)
                end
                local sel = params.Selection
                if OptionsListMenu == "SongMenu" or OptionsListMenu == "AdvMenu" then
                    if sel+1 <= numRows then
                        local itemName = string.gsub(THEME:GetMetric("ScreenOptionsMaster",OptionsListMenu..","..params.Selection+1):split(";")[1],"name,","")
                        self:GetChild("Explanation"):GetChild("ExpText"):settext(THEME:GetString("OptionExplanations",itemName))
                    else
                        self:GetChild("Explanation"):GetChild("ExpText"):settext("Exit.")
                    end
                else
                    if OptionsListMenu ~= "Exit" then
                        if OptionsListMenu == "Gauge" then
                            if IsExtraStage1() then
                                sel = (sel == 1) and 2 or 1
                            elseif IsExtraStage2() then
                                sel = 2
                            end
                        end

                        if THEME:GetMetric("ScreenOptionsMaster",OptionsListMenu.."Explanation") then
                            self:GetChild("Explanation"):GetChild("ExpText"):settext(THEME:GetString("OptionListItemExplanations",OptionsListMenu..tostring(params.Selection)))
                        else
                            self:GetChild("Explanation"):GetChild("ExpText"):settext("")
                        end
                    else
                        -- XXX: Isn't this redundant? As this code branch only runs if OptionsListMenu == "Exit"
                        if OptionsListMenu == "Mini"
                        or OptionsListMenu == "Characters"
                        or OptionsListMenu == "DanceStage"
                        or OptionsListMenu == "Mate1"
                        or OptionsListMenu == "Mate2"
                        or OptionsListMenu == "Mate3"
                        or OptionsListMenu == "Mate4"
                        or OptionsListMenu == "Mate5"
                        or OptionsListMenu == "Mate6"
                        or OptionsListMenu == "NoteSkins"
                        or OptionsListMenu == "MusicRate" then
                            self:GetChild("Explanation"):GetChild("ExpText"):settext(THEME:GetString("OptionExplanations",OptionsListMenu))
                        end
                    end
                end
            end
        end,

        Def.ActorFrame{
            Name="PlayerFrame",
            Def.Sprite{ Texture="Backer",};
            Def.Sprite{
                Texture="Backer",
            };
            Def.ActorFrame{
                InitCommand=function(s) s:y(-364) end,
                Def.Sprite{
                    Texture="top",
                };
                Def.Sprite{
                    Texture="color",
                    InitCommand=function(s) s:y(12):diffuse(PlayerColor(pn)) end,
                };
            }
        };

        Def.ActorFrame{
            Name="Explanation",
            InitCommand=function(s) s:y(401) end,
            OnCommand=function(s) s:diffusealpha(1):sleep(0.05):diffusealpha(0):sleep(0.05):diffusealpha(1):sleep(0.05):diffusealpha(0):sleep(0.05):diffusealpha(1):sleep(0.05):diffusealpha(0):sleep(0.05):linear(0.05):diffusealpha(1) end,
		    OffCommand=function(s) s:diffusealpha(1):sleep(0.05):diffusealpha(0):sleep(0.05):diffusealpha(1):sleep(0.05):diffusealpha(0):sleep(0.05):diffusealpha(1):sleep(0.05):diffusealpha(0):sleep(0.05) end,
		    Def.Sprite{ Texture="exp.png", };
            Def.BitmapText{
                Name="ExpText",
                Font="_avenirnext lt pro bold/25px",
                InitCommand=function(s) s:wrapwidthpixels(420) end,
            },
        },

        Def.BitmapText{
            Font="_avenirnext lt pro bold/25px",
            InitCommand=function(s) s:y(-300) end,
            OptionsListOpenedMessageCommand=function(s,p)
                s:playcommand("UpdateText")
            end,
            UpdateTextMessageCommand= function(self)
                local speed, mode= GetSpeedModeAndValueFromPoptions(pn)
                -- Courses don't have GetDisplayBpms.
                if GAMESTATE:GetCurrentSong() then
                    song_bpms= GAMESTATE:GetCurrentSong():GetDisplayBpms()
                    song_bpms[1]= math.round(song_bpms[1])
                    song_bpms[2]= math.round(song_bpms[2])
                    if song_bpms[1] == song_bpms[2] then
                        bpm_text= format_bpm(song_bpms[1])
                    else
                        bpm_text= format_bpm(song_bpms[1]) .. " - " .. format_bpm(song_bpms[2])
                    end
                end
                local text= ""
                local no_change= true
                if mode == "x" then
                    if not song_bpms[1] then
                        text= "??? - ???"
                    elseif song_bpms[1] == song_bpms[2] then
                        text= "x"..(speed/100).." ("..format_bpm(song_bpms[1] * speed*.01)..")"
                    else
                        text= "x"..(speed/100).." ("..format_bpm(song_bpms[1] * speed*.01) .. " - " ..
                            format_bpm(song_bpms[2] * speed*.01)..")"
                    end
                    no_change= speed == 100
                elseif mode == "C" then
                    text= mode .. speed
                    no_change= speed == song_bpms[2] and song_bpms[1] == song_bpms[2]
                else
                    no_change= speed == song_bpms[2]
                    if song_bpms[1] == song_bpms[2] then
                        text= mode .. speed
                    else
                        local factor= song_bpms[1] / song_bpms[2]
                        text= mode .. format_bpm(speed * factor) .. " - "
                            .. mode .. speed
                    end
                end
                if GAMESTATE:IsCourseMode() then
                    if mode == "x" then
                        text = "x"..(speed/100)
                    else
                        text = mode .. speed
                    end
                    self:settext("Current Velocity: "..text)
                else
                    self:settext("Current Velocity: "..text):zoom(1)
                end
            end,
            AdjustCommand=function(self,params)
                if OptionsListMenu then
                    if OptionsListMenu == "SongMenu" or string.find(OptionsListMenu, "Speed") then
                        self:queuecommand("UpdateText");
                        self:visible(true)
                    else
                        self:visible(false)
                    end
                else
                    self:visible(false)
                end
            end;
            SpeedModChangedMessageCommand=function(self,params)
                if params.PlayerNumber == pn then
                    return self:queuecommand("Adjust")
                end;
            end;
        };

        -- Masks that will hide the off limits portion of the list, shhh
        Def.Quad {
            InitCommand=function(self) self:setsize(620, 360):xy(0, -285):valign(1):MaskSource() end,
        },
        Def.Quad {
            InitCommand=function(self) self:setsize(620, 360):xy(0, 336):valign(0):MaskSource() end,
        },
        
        --Mini
        Def.ActorFrame{
            InitCommand=function(s) s:y(-100):zoom(1):diffusealpha(0) end,
            OptionsMenuChangedMessageCommand=function(self,params)
                if params.Player == pn then
                    if params.Menu == "Mini" then
                        self:playcommand("On")
                        self:stoptweening():linear(.3):diffusealpha(1);
                    else
                        self:diffusealpha(0);
                    end;
                end;
            end;
            Def.BitmapText{
                Font="_avenirnext lt pro bold/36px",
                InitCommand=function(s) s:y(180):maxwidth(500):strokecolor(Color.Black) end,
                OnCommand=function(self)
                    if CurrentMiniVal(pn) ~= nil then
                        self:settext("Select\n"..CurrentMiniVal(pn).."%\nas your Mini value.")
                    else
                        self:settext("Invalid mini value is set.")
                    end
                end,
                AdjustCommand=function(self,params)
                    if params.Player == pn and OptionsListMenu == "Mini" then
                        if params.Selection < #NumMini then
                            if NumMini[params.Selection+1] == "EXIT" then
                                self:settext("Exit.")
                            else
                                self:settext("Select\n"..string.format("%01d",NumMini[params.Selection+1]).."%\nas your Mini value.")
                            end
                        else
                            self:settext("")
                        end
                    end
                end,
            };
            Def.ActorScroller{
                Name="Mini Scroller",
                NumItemsToDraw=5;
                SecondsPerItem=0.2;
                children = _MINI;
                InitCommand=function(s)
                    s:SetLoop(true):SetWrap(true)
                    :SetDrawByZPosition(true):SetFastCatchup(true)
                end,
                OptionsMenuChangedMessageCommand=function(self,params)
                    if params.Player == pn then
                        if GetMiniIndex(CurrentMiniVal(pn)) ~= nil then
                            
                            self:SetCurrentAndDestinationItem(GetMiniIndex(CurrentMiniVal(pn))-1)
                        else
                            self:SetCurrentAndDestinationItem(0)
                        end
                    end;
                end;
                TransformFunction=function(s,offset,itemIndex,numItems)
                    local sign = offset == 0 and 1 or offset/math.abs(offset)
                    s:x((offset*160*math.cos((math.pi/10*offset))+math.min(math.abs(offset),1)*sign*0))
                    :z((offset*-62*3*math.sin((math.pi/10)*offset))+(math.min(math.abs(offset),1)*0))
                    :rotationy(offset*(360/(10*1.135)))
                end,
                AdjustCommand=function(self,params)
                    if params.Player == pn and OptionsListMenu == "Mini" then
                        self:SetDestinationItem(params.Selection)
                    end
                end,
            };
            Def.Sprite{
                Texture="arrow",
                InitCommand=function(s) s:x(-260):zoom(2):diffusealpha(1):bounce():effectmagnitude(3,0,0):effectperiod(1) end,
                OptionsListLeftMessageCommand=function(s) s:finishtweening():diffuse(color("#8080ff")):sleep(0.3):linear(0.4):diffuse(color("1,1,1,1")) end,
            };
            Def.Sprite{
                Texture="arrow",
                InitCommand=function(s) s:x(260):basezoom(2):zoomx(-1):diffusealpha(1):bounce():effectmagnitude(-3,0,0):effectperiod(1) end,
                OptionsListRightMessageCommand=function(s) s:finishtweening():diffuse(color("#8080ff")):sleep(0.3):linear(0.4):diffuse(color("1,1,1,1")) end,
            };
        };
        --NoteSkin
        Def.ActorFrame{
            InitCommand=function(s) s:y(-100):zoom(1):diffusealpha(0) end,
            OptionsMenuChangedMessageCommand=function(self,params)
                if params.Player == pn then
                    if params.Menu == "NoteSkins" then
                        self:playcommand("On")
                        self:stoptweening():linear(.3):diffusealpha(1);
                    else
                        self:diffusealpha(0);
                    end;
                end;
            end;
            Def.BitmapText{
                Condition=ThemePrefs.Get("ExclusiveNS") == true,
                Font="_avenirnext lt pro bold/36px",
                Text="Exclusive NoteSkins:",
                InitCommand=function(s) s:y(-180):maxwidth(500):DiffuseAndStroke(color("#00AAFF"),(color("#0030FF"))) end,
            };
            Def.BitmapText{
                Font="_avenirnext lt pro bold/36px",
                InitCommand=function(s) s:y(180):maxwidth(500):strokecolor(Color.Black) end,
                OnCommand=function(self)
                    if CurrentNoteSkin(pn) ~= nil then
                        self:settext("Select\n"..CurrentNoteSkin(pn).."\nNote Skin")
                    else
                        self:settext("Invalid noteskin is set.")
                    end
                end,
                AdjustCommand=function(self,params)
                    if params.Player == pn and OptionsListMenu == "NoteSkins" then
                        if params.Selection < OPTIONSLIST_NUMNOTESKINS then
                            highlightedNoteSkin = OPTIONSLIST_NOTESKINS[params.Selection+1];
                            self:settext("Select\n"..highlightedNoteSkin.. "\nNote Skin")
                        else
                            self:settext("")
                        end
                    end
                end,
            };
            Def.ActorScroller{
                Name="Noteskin Scroller",
                NumItemsToDraw=5;
                SecondsPerItem=0.2;
                children = _NSKIN;
                InitCommand=function(s)
                    s:SetLoop(true):SetWrap(true)
                    :SetDrawByZPosition(true):SetFastCatchup(true)
                end,
                OptionsMenuChangedMessageCommand=function(self,params)
                    if params.Player == pn then
                        if GetCNSIndex(CurrentNoteSkin(pn)) ~= nil then
                            self:SetCurrentAndDestinationItem(GetCNSIndex(CurrentNoteSkin(pn))-1)
                        else
                            self:SetCurrentAndDestinationItem(0)
                        end
                    end;
                end;
                TransformFunction=function(s,offset,itemIndex,numItems)
                    local sign = offset == 0 and 1 or offset/math.abs(offset)
                    s:x((offset*160*math.cos((math.pi/10*offset))+math.min(math.abs(offset),1)*sign*0))
                    :z((offset*-62*3*math.sin((math.pi/10)*offset))+(math.min(math.abs(offset),1)*0))
                    :rotationy(offset*(360/(10*1.135)))
                end,
                AdjustCommand=function(self,params)
                    if params.Player == pn and OptionsListMenu == "NoteSkins" then
                        self:SetDestinationItem(params.Selection)
                    end
                end,
            };
            Def.Sprite{
                Texture="arrow",
                InitCommand=function(s) s:x(-260):zoom(2):diffusealpha(1):bounce():effectmagnitude(3,0,0):effectperiod(1) end,
                OptionsListLeftMessageCommand=function(s) s:finishtweening():diffuse(color("#8080ff")):sleep(0.3):linear(0.4):diffuse(color("1,1,1,1")) end,
            };
            Def.Sprite{
                Texture="arrow",
                InitCommand=function(s) s:x(260):basezoom(2):zoomx(-1):diffusealpha(1):bounce():effectmagnitude(-3,0,0):effectperiod(1) end,
                OptionsListRightMessageCommand=function(s) s:finishtweening():diffuse(color("#8080ff")):sleep(0.3):linear(0.4):diffuse(color("1,1,1,1")) end,
            };
        };
        --Mini
        Def.ActorFrame{
            InitCommand=function(s) s:y(-100):zoom(1):diffusealpha(0) end,
            OptionsMenuChangedMessageCommand=function(self,params)
                if params.Player == pn then
                    if params.Menu == "MusicRate" then
                        self:playcommand("On")
                        self:stoptweening():linear(.3):diffusealpha(1);
                    else
                        self:diffusealpha(0);
                    end;
                end;
            end;
            Def.BitmapText{
                Font="_avenirnext lt pro bold/36px",
                InitCommand=function(s) s:y(180):maxwidth(500):strokecolor(Color.Black) end,
                OnCommand=function(self)
                    if CurrentRateVal(pn) ~= nil then
                        self:settext("Select\n"..CurrentRateVal(pn).."%\nas your song speed.")
                    else
                        self:settext("Invalid song speed is set.")
                    end
                end,
                AdjustCommand=function(self,params)
                    if params.Player == pn and OptionsListMenu == "MusicRate" then
                        if params.Selection < #NumRate then
                            if NumRate[params.Selection+1] == "EXIT" then
                                self:settext("Exit.")
                            else
                                self:settext("Select\n"..string.format("%01d",NumRate[params.Selection+1]).."%\nas song speed.")
                            end
                        else
                            self:settext("")
                        end
                    end
                end,
            };
            --MusicRate
            Def.ActorScroller{
                Name="MusicRate Scroller",
                NumItemsToDraw=5;
                SecondsPerItem=0.2;
                children = _RATE;
                InitCommand=function(s)
                    s:SetLoop(true):SetWrap(true)
                    :SetDrawByZPosition(true):SetFastCatchup(true)
                end,
                OptionsMenuChangedMessageCommand=function(self,params)
                    if params.Player == pn then
                        if GetRateIndex(CurrentRateVal(pn)) ~= nil then
                            
                            self:SetCurrentAndDestinationItem(GetRateIndex(CurrentRateVal(pn))-1)
                        else
                            self:SetCurrentAndDestinationItem(0)
                        end
                    end;
                end;
                TransformFunction=function(s,offset,itemIndex,numItems)
                    local sign = offset == 0 and 1 or offset/math.abs(offset)
                    s:x((offset*160*math.cos((math.pi/10*offset))+math.min(math.abs(offset),1)*sign*0))
                    :z((offset*-62*3*math.sin((math.pi/10)*offset))+(math.min(math.abs(offset),1)*0))
                    :rotationy(offset*(360/(10*1.135)))
                end,
                AdjustCommand=function(self,params)
                    if params.Player == pn and OptionsListMenu == "MusicRate" then
                        self:SetDestinationItem(params.Selection)
                    end
                end,
            };
            Def.Sprite{
                Texture="arrow",
                InitCommand=function(s) s:x(-260):zoom(2):diffusealpha(1):bounce():effectmagnitude(3,0,0):effectperiod(1) end,
                OptionsListLeftMessageCommand=function(s) s:finishtweening():diffuse(color("#8080ff")):sleep(0.3):linear(0.4):diffuse(color("1,1,1,1")) end,
            };
            Def.Sprite{
                Texture="arrow",
                InitCommand=function(s) s:x(260):basezoom(2):zoomx(-1):diffusealpha(1):bounce():effectmagnitude(-3,0,0):effectperiod(1) end,
                OptionsListRightMessageCommand=function(s) s:finishtweening():diffuse(color("#8080ff")):sleep(0.3):linear(0.4):diffuse(color("1,1,1,1")) end,
            };
        };
        Def.ActorFrame{
            InitCommand=function(s) s:y(-295):zoom(1):diffusealpha(0) end,
            OptionsMenuChangedMessageCommand=function(self,params)
                if params.Player == pn then
                    if params.Menu == "CharaDS" or params.Menu == "DMates" then
                        self:playcommand("On")
                        self:stoptweening():linear(.3):diffusealpha(1);
                    else
                        self:diffusealpha(0);
                    end;
                end;
            end;
            
            Def.ActorFrame{
                InitCommand =function(s) s:y(45) end,
                AdjustCommand=function(s, params)
                    if not (params.Type == 'OptionsListQuickChange' and OptionsListMenu == "DMates") then return end
                    -- Special case for when we use START+LEFT or START+RIGHT to change the character
                    -- We should probably do some check so we don't always update all 6 mate sprites when only one needs to update
                    -- Perhaps cache the current key for each mate and check for difference?
                    for i=1, 6 do
                        local name = 'Mate' .. i
                        local key = getUserPrefKeyFunc(name)(pn)
                        local image = getSelectionImage(key, SelectionTable.Characters.getAssetPath, SelectionTable.Characters.specialKeyImages)
                        s:GetChild(name .. 'Sprite'):Load(image)
                    end
                end,
                Def.BitmapText{
                    Font="_avenirnext lt pro bold/20px",
                    Text="Mate 1",
                    InitCommand=function(s) s:xy(-227,-60):zoom(0.9) end,
                };
                Def.Sprite{
                    Name="Mate1Sprite",
                    OnCommand=function(s)
                        local key = getUserPrefKeyFunc('Mate1')(pn)
                        local image = getSelectionImage(key, SelectionTable.Characters.getAssetPath, SelectionTable.Characters.specialKeyImages)
                        s:Load(image)
                        s:zoom(0.1):x(-227)
                    end,
                };
                Def.BitmapText{
                    Font="_avenirnext lt pro bold/20px",
                    Text="Mate 2",
                    InitCommand=function(s) s:xy(-135,-60):zoom(0.9) end,
                };
                Def.Sprite{
                    Name="Mate2Sprite",
                    OnCommand=function(s)
                        local key = getUserPrefKeyFunc('Mate2')(pn)
                        local image = getSelectionImage(key, SelectionTable.Characters.getAssetPath, SelectionTable.Characters.specialKeyImages)
                        s:Load(image)
                        s:zoom(0.1):x(-135)
                    end,
                };
                Def.BitmapText{
                    Font="_avenirnext lt pro bold/20px",
                    Text="Mate 3",
                    InitCommand=function(s) s:xy(-45,-60):zoom(0.9) end,
                };
                Def.Sprite{
                    Name="Mate3Sprite",
                    OnCommand=function(s)
                        local key = getUserPrefKeyFunc('Mate3')(pn)
                        local image = getSelectionImage(key, SelectionTable.Characters.getAssetPath, SelectionTable.Characters.specialKeyImages)
                        s:Load(image)
                        s:zoom(0.1):x(-45)
                    end,
                };
                Def.BitmapText{
                    Font="_avenirnext lt pro bold/20px",
                    Text="Mate 4",
                    InitCommand=function(s) s:xy(45,-60):zoom(0.9) end,
                };
                Def.Sprite{
                    Name="Mate4Sprite",
                    OnCommand=function(s)
                        local key = getUserPrefKeyFunc('Mate4')(pn)
                        local image = getSelectionImage(key, SelectionTable.Characters.getAssetPath, SelectionTable.Characters.specialKeyImages)
                        s:Load(image)
                        s:zoom(0.1):x(45)
                    end,
                };
                Def.BitmapText{
                    Font="_avenirnext lt pro bold/20px",
                    Text="Mate 5",
                    InitCommand=function(s) s:xy(135,-60):zoom(0.9) end,
                };
                Def.Sprite{
                    Name="Mate5Sprite",
                    OnCommand=function(s)
                        local key = getUserPrefKeyFunc('Mate5')(pn)
                        local image = getSelectionImage(key, SelectionTable.Characters.getAssetPath, SelectionTable.Characters.specialKeyImages)
                        s:Load(image)
                        s:zoom(0.1):x(135)
                    end,
                };
                Def.BitmapText{
                    Font="_avenirnext lt pro bold/20px",
                    Text="Mate 6",
                    InitCommand=function(s) s:xy(227,-60):zoom(0.9) end,
                };
                Def.Sprite{
                    Name="Mate6Sprite",
                    OnCommand=function(s)
                        local key = getUserPrefKeyFunc('Mate6')(pn)
                        local image = getSelectionImage(key, SelectionTable.Characters.getAssetPath, SelectionTable.Characters.specialKeyImages)
                        s:Load(image)
                        s:zoom(0.1):x(227)
                    end,
                };
            };
            
            Def.ActorFrame{
                InitCommand = function(s) s:y(275) end,
                OptionsMenuChangedMessageCommand=function(self,params)
                    if params.Player == pn then
                        if params.Menu == "CharaDS" then
                            self:playcommand("On")
                            self:stoptweening():linear(.3):diffusealpha(1);
                        else
                            self:diffusealpha(0);
                        end;
                    end;
                end;
                Def.ActorFrame{
                    InitCommand = function(s) s:x(-140) end,
                    AdjustCommand=function(s, params)
                        if not (params.Type == 'OptionsListQuickChange' and OptionsListMenu == "CharaDS") then return end
                        -- Special case for when we use START+LEFT or START+RIGHT to change the character
                        local key = getUserPrefKeyFunc('Characters')(pn)
                        local image = getSelectionImage(key, SelectionTable.Characters.getAssetPath, SelectionTable.Characters.specialKeyImages)
                        s:GetChild('Sprite'):Load(image)
                        s:GetChild('Text'):settext(key)
                    end,
                    Def.BitmapText{
                        Font="_avenirnext lt pro bold/25px",
                        Text="Player Character",
                        InitCommand=function(s) s:y(-158) end,
                    };
                    Def.Sprite{
                        Name='Sprite',
                        OnCommand=function(s)
                            local key = getUserPrefKeyFunc('Characters')(pn)
                            local image = getSelectionImage(key, SelectionTable.Characters.getAssetPath, SelectionTable.Characters.specialKeyImages)
                            s:Load(image)
                            s:zoom(0.30)
                        end,
                    };
                    Def.Sprite{
                        Texture="cards/BAR.png",
                        InitCommand=function(s) s:zoom(0.30) end,
                    };
                    Def.BitmapText{
                        Name='Text',
                        Font="_avenirnext lt pro bold/20px",
                        OnCommand=function(s) 
                            local key = getUserPrefKeyFunc('Characters')(pn)
                            s:settext(key)
                            s:y(120):zoom(1)
                        end,
                    };
                };
                Def.ActorFrame{
                    InitCommand = function(s) s:x(140) end,
                    AdjustCommand=function(s, params)
                        if not (params.Type == 'OptionsListQuickChange' and OptionsListMenu == "CharaDS") then return end
                        -- Special case for when we use START+LEFT or START+RIGHT to change the stage
                        local key = getUserPrefKeyFunc('SelectDanceStage')(pn)
                        local image = getSelectionImage(key, SelectionTable.DanceStages.getAssetPath, SelectionTable.DanceStages.specialKeyImages)
                        s:GetChild('Sprite'):Load(image)
                        s:GetChild('Text'):settext(key)
                    end,
                    Def.BitmapText{
                        Font="_avenirnext lt pro bold/25px",
                        Text="Dance Stage",
                        InitCommand=function(s) s:y(-158) end,
                    };
                    Def.Sprite{
                        Name="Sprite",
                        OnCommand=function(s)
                            local key = getUserPrefKeyFunc('SelectDanceStage')(pn)
                            local image = getSelectionImage(key, SelectionTable.DanceStages.getAssetPath, SelectionTable.DanceStages.specialKeyImages)
                            s:Load(image)
                            s:zoom(0.30)
                        end,
                    };
                    Def.Sprite{
                        Texture="cards/BAR.png",
                        InitCommand=function(s) s:zoom(0.30) end,
                    };
                    Def.BitmapText{
                        Name="Text",
                        Font="_avenirnext lt pro bold/20px",
                        OnCommand=function(s) 
                            local key = getUserPrefKeyFunc('SelectDanceStage')(pn)
                            s:settext(key)
                            s:y(120):zoom(1)
                        end,
                    };
                };
            };
        };
        
        createSelectionScroller('Characters', _CHAR,     fixedChar, getUserPrefKeyFunc('Characters'),       SelectionTable.Characters.getAssetPath,  SelectionTable.Characters.specialKeyImages),
        createSelectionScroller('Mate1',      _CHAR,     fixedChar, getUserPrefKeyFunc('Mate1'),            SelectionTable.Characters.getAssetPath,  SelectionTable.Characters.specialKeyImages),
        createSelectionScroller('Mate2',      _CHAR,     fixedChar, getUserPrefKeyFunc('Mate2'),            SelectionTable.Characters.getAssetPath,  SelectionTable.Characters.specialKeyImages),
        createSelectionScroller('Mate3',      _CHAR,     fixedChar, getUserPrefKeyFunc('Mate3'),            SelectionTable.Characters.getAssetPath,  SelectionTable.Characters.specialKeyImages),
        createSelectionScroller('Mate4',      _CHAR,     fixedChar, getUserPrefKeyFunc('Mate4'),            SelectionTable.Characters.getAssetPath,  SelectionTable.Characters.specialKeyImages),
        createSelectionScroller('Mate5',      _CHAR,     fixedChar, getUserPrefKeyFunc('Mate5'),            SelectionTable.Characters.getAssetPath,  SelectionTable.Characters.specialKeyImages),
        createSelectionScroller('Mate6',      _CHAR,     fixedChar, getUserPrefKeyFunc('Mate6'),            SelectionTable.Characters.getAssetPath,  SelectionTable.Characters.specialKeyImages),
        createSelectionScroller('DanceStage', _DS, DanceStagesList, getUserPrefKeyFunc('SelectDanceStage'), SelectionTable.DanceStages.getAssetPath, SelectionTable.DanceStages.specialKeyImages),
    }
end

return t
