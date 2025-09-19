local function CreditsText()
	local text = Def.BitmapText{
		Font="_avenirnext lt pro bold/20px",
		InitCommand=function(s) s:xy(_screen.cx,SCREEN_BOTTOM-16):strokecolor(Color.Black):playcommand("Refresh") end,
		RefreshCommand=function(self)
		--Other coin modes
			if GAMESTATE:IsEventMode() then self:settext('EVENT MODE') return end
			if GAMESTATE:GetCoinMode()=='CoinMode_Free' then self:settext('FREE PLAY') return end
			if GAMESTATE:GetCoinMode()=='CoinMode_Home' then self:settext('HOME MODE') return end
			if GAMESTATE:GetCoinMode()=='CoinMode_Pay' then
				local coins=GAMESTATE:GetCoins()
				local coinsPerCredit=PREFSMAN:GetPreference('CoinsPerCredit')
				local credits=math.floor(coins/coinsPerCredit)
				local remainder=math.mod(coins,coinsPerCredit)
				local add = ''
				if coinsPerCredit > 1 then
					add = " ("..remainder.."/"..coinsPerCredit..")"
				end
				self:settext("CREDIT(S): "..credits..add)
			end
		end;
		UpdateVisibleCommand=function(self)
			local screen = SCREENMAN:GetTopScreen();
			local bShow = true;
			if screen then
				local sClass = screen:GetName();
				bShow = THEME:GetMetric( sClass, "ShowCreditDisplay" );
			end;

			self:visible( bShow );
		end;
		CoinInsertedMessageCommand=function(s) s:stoptweening():playcommand("Refresh") end,
		RefreshCreditTextMessageCommand=function(s) s:stoptweening():playcommand("Refresh") end,
		PlayerJoinedMessageCommand=function(s) s:stoptweening():playcommand("Refresh") end,
		ScreenChangedMessageCommand=function(s) s:stoptweening():playcommand("Refresh") end,
	};
	return text;
end;

local function PlayerText( pn )
	local text = Def.BitmapText{
		Font="_avenirnext lt pro bold/20px",
		InitCommand=function(s) s:name("Credits" .. PlayerNumberToString(pn))
			ActorUtil.LoadAllCommandsAndSetXY(s,Var "LoadingScreen")
			s:maxwidth(325):strokecolor(Color.Black)
		end,
		UpdateTextCommand=function(s)
			s:settext(PROFILEMAN:GetProfile(pn):GetDisplayName())
		end;
		UpdateVisibleCommand=function(self)
			local screen = SCREENMAN:GetTopScreen();
			local bShow = true;
			if screen then
				local sClass = screen:GetName();
				bShow = THEME:GetMetric( sClass, "ShowCreditDisplay" );
			end

			self:visible( bShow );
		end
	};
	return text;
end;

local t = Def.ActorFrame {}

if ThemePrefs.Get("BurnInProtect") ~= true then
t[#t+1] = Def.ActorFrame {
	CreditsText();
	PlayerText( PLAYER_1 );
	PlayerText( PLAYER_2 );
};
end

-- Text
t[#t+1] = Def.ActorFrame {
	Def.Quad {
		InitCommand=function(s) s:zoomto(SCREEN_WIDTH,34):align(0,0):y(SCREEN_TOP):diffuse(color("0,0,0,0")) end,
		OnCommand=function(s) s:finishtweening():diffusealpha(0.85) end,
		OffCommand=function(s) s:sleep(3):linear(0.5):diffusealpha(0) end,
	};
	Def.BitmapText{
		Font="_avenirnext lt pro bold/25px";
		Name="Text";
		InitCommand=function(s) s:maxwidth(750):align(0,0):xy(SCREEN_LEFT+10,SCREEN_TOP+8):shadowlength(1):diffusealpha(0) end,
		OnCommand=function(s) s:finishtweening():diffusealpha(1) end,
		OffCommand=function(s) s:sleep(3):linear(0.5):diffusealpha(0) end,
	};
	SystemMessageMessageCommand = function(self, params)
		self:GetChild("Text"):settext( params.Message );
		self:playcommand( "On" );
		if params.NoAnimate then
			self:finishtweening();
		end
		self:playcommand( "Off" );
	end;
	HideSystemMessageMessageCommand = function(s) s:finishtweening() end,
};

local OverlayScreen
local inputCallbacks = {}
function AddOverlayInputCallback(callback)
	if not OverlayScreen then
		error('AddOverlayInputCallback(): Cannot be called before overlay screen object is retrieved.')
	end
	table.insert(inputCallbacks, callback)
	OverlayScreen:AddInputCallback(callback)
end
function RemoveOverlayInputCallback(callback)
	if not OverlayScreen then
		error('RemoveOverlayInputCallback(): Cannot be called before overlay screen object is retrieved.')
	end
	table.remove(inputCallbacks, callback)
	OverlayScreen:RemoveInputCallback(callback)
end

t[#t+1] = Def.Actor{
	BeginCommand=function(self)
		OverlayScreen = self:GetParent():GetParent()
		if not OverlayScreen or OverlayScreen:GetName() ~= Var('LoadingScreen') then
			error('Failed to get overlay screen! AddOverlayInputCallback() and RemoveOverlayInputCallback() will not work!')
		end
	end,
	ScreenChangedMessageCommand=function()
		-- Because overlay screens are persistent, we need to remove callbacks manually to make it behave like expected
		if #inputCallbacks == 0 then return end		
		for _, callback in pairs(inputCallbacks) do
			RemoveOverlayInputCallback(callback)
		end
	end
}

return t
