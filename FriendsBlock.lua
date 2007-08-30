
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

FriendsBlock = DongleStub("Dongle-1.0"):New("FriendsBlock")
local lego = DongleStub("LegoBlock-Beta0"):New("FriendsBlock", "50/50", "Interface\\Addons\\FriendsBlock\\icon")
--~ if tekDebug then FriendsBlock:EnableDebug(1, tekDebug:GetFrame("FriendsBlock")) end


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

function FriendsBlock:Initialize()
	local blockdefaults = {
		locked = false,
		showIcon = true,
		showText = true,
		shown = true,
	}

	self.db = self:InitializeDB("FriendsBlockDB", {profile = {block = blockdefaults}}, "global")
end


function FriendsBlock:Enable()
	lego:SetDB(self.db.profile.block)

	self:RegisterEvent("FRIENDLIST_UPDATE")
	self:RegisterEvent("CHAT_MSG_SYSTEM")

	lego:SetScript("OnUpdate", OnUpdate)
	ShowFriends()
end


------------------------------
--      Event Handlers      --
------------------------------

function FriendsBlock:CHAT_MSG_SYSTEM(event, msg)
	if string.find(msg, L["has come online"]) or string.find(msg, L["has gone offline"]) then dirty = true end
end


function FriendsBlock:FRIENDLIST_UPDATE()
	local online = 0
	total = 0

	local uid = GetTime()
	for i = 1,GetNumFriends() do
		local name, level, class, area, connected = GetFriendInfo(i)

		if name then
			if not friends[name] then friends[name] = {} end
			total = total + 1

			local t = friends[name]
			t.uid = uid
			t.level = level
			t.class = class
			t.area  = area
			t.connected = connected
			if connected then online = online + 1 end
		end
	end

	-- Purge out deleted friends
	for name,data in pairs(friends) do if data.uid ~= uid then friends[name] = nil end end

	lego:SetText(total > 0 and string.format("%d/%d", online, total) or L["Emo"])
end


------------------------
--      Tooltip!      --
------------------------

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()/2) and "RIGHT" or "LEFT"
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end


lego:SetScript("OnLeave", function() GameTooltip:Hide() end)
lego:SetScript("OnEnter", function(self)
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()

	GameTooltip:AddLine("FriendsBlock")

	local online
	for name,data in pairs(friends) do
		if data.connected then
			online = true
			GameTooltip:AddDoubleLine(string.format("|cff%s%s:%s|r", colors[data.class:upper()] or "000000", data.level or "", name), "|cffffffff"..(data.area or ""))
		end
	end

	if total == 0 then GameTooltip:AddLine(L["You have no friends!"])
	elseif not online then GameTooltip:AddLine(L["No Friends Online"]) end

	GameTooltip:Show()
end)


------------------------------------------
--      Click to open friend panel      --
------------------------------------------

lego:EnableMouse(true)
lego:RegisterForClicks("anyUp")
lego:SetScript("OnClick", function()
	if FriendsFrame:IsVisible() then HideUIPanel(FriendsFrame)
	else
		ToggleFriendsFrame(1)
		FriendsFrame_Update()
	end
end)

