
----------------------------
--      Localization      --
----------------------------

local L = {
	offline = "(.+) has gone offline.";
	online = "|Hplayer:%s|h[%s]|h has come online.";	["has come online"] = "has come online",
	["has gone offline"] = "has gone offline",

	["Level"] = "Level",
	["Name"] = "Name",
	["Emo"] = "Emo",
	["No Friends Online"] = "No Friends Online",
	["You have no friends!"] = "You have no friends!",
}


------------------------------
--      Are you local?      --
------------------------------

local friends, colors, total = {}, {}, 0
for class,color in pairs(RAID_CLASS_COLORS) do colors[class] = string.format("%02x%02x%02x", color.r*255, color.g*255, color.b*255) end


-------------------------------------------
--      Namespace and all that shit      --
-------------------------------------------

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")


local dataobj = {icon = "Interface\\Addons\\FriendsBlock\\icon", text = "50/50"}
LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("FriendsBlock", dataobj)


----------------------------------
--      Server query timer      --
----------------------------------

local MINDELAY, DELAY = 15, 300
local elapsed, dirty = 0, false
local function OnUpdate(self, el)
	elapsed = elapsed + el
	if (dirty and elapsed >= MINDELAY) or elapsed >= DELAY then ShowFriends() end
end


local orig = ShowFriends
ShowFriends = function(...)
	elapsed, dirty = 0, false
	return orig(...)
end


---------------------------
--      Init/Enable      --
---------------------------

function f:ADDON_LOADED()
	if FriendsBlockDB and FriendsBlockDB.profiles then FriendsBlockDB = nil end
	FriendsBlockDB = FriendsBlockDB or {}

	LibStub:GetLibrary("tekBlock"):new("FriendsBlock", FriendsBlockDB)

	f:UnregisterEvent("ADDON_LOADED")
	f.ADDON_LOADED = nil

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end


function f:PLAYER_LOGIN()
	self:RegisterEvent("FRIENDLIST_UPDATE")
	self:RegisterEvent("CHAT_MSG_SYSTEM")

	f:SetScript("OnUpdate", OnUpdate)
	ShowFriends()

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end


------------------------------
--      Event Handlers      --
------------------------------

function f:CHAT_MSG_SYSTEM(event, msg)
	if string.find(msg, L["has come online"]) or string.find(msg, L["has gone offline"]) then dirty = true end
end


function f:FRIENDLIST_UPDATE()
	local online = 0
	total = 0

	local uid = GetTime()
	for i = 1,GetNumFriends() do
		local name, level, class, area, connected, status = GetFriendInfo(i)

		if name then
			if not friends[name] then friends[name] = {} end
			total = total + 1

			local t = friends[name]
			t.uid = uid
			t.level = level
			t.class = class
			t.area  = area
			t.status = status
			t.connected = connected
			if connected then online = online + 1 end
		end
	end

	-- Purge out deleted friends
	for name,data in pairs(friends) do if data.uid ~= uid then friends[name] = nil end end

	dataobj.text = total > 0 and string.format("%d/%d", online, total) or L["Emo"]
end


------------------------
--      Tooltip!      --
------------------------

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end


function dataobj.OnLeave() GameTooltip:Hide() end
function dataobj.OnEnter(self)
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()

	GameTooltip:AddLine("FriendsBlock")

	local online
	for name,data in pairs(friends) do
		if data.connected then
			online = true
			GameTooltip:AddDoubleLine(string.format("|cff%s%s:%s|r %s", colors[data.class:upper()] or "000000", data.level or "", name, data.status), "|cffffffff"..(data.area or ""))
		end
	end

	if total == 0 then GameTooltip:AddLine(L["You have no friends!"])
	elseif not online then GameTooltip:AddLine(L["No Friends Online"]) end

	GameTooltip:Show()
end


------------------------------------------
--      Click to open friend panel      --
------------------------------------------

function dataobj.OnClick()
	if FriendsFrame:IsVisible() then HideUIPanel(FriendsFrame)
	else
		ToggleFriendsFrame(1)
		FriendsFrame_Update()
		GameTooltip:Hide()
	end
end
