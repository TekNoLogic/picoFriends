
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

local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("picoFriends", {type = "data source", icon = "Interface\\Addons\\picoFriends\\icon", text = "50/50"})
local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)


----------------------------------
--      Server query timer      --
----------------------------------

local MINDELAY, DELAY = 15, 300
local elapsed, dirty = 0, false
f:Hide()
f:SetScript("OnUpdate", function (self, el)
	elapsed = elapsed + el
	if (dirty and elapsed >= MINDELAY) or elapsed >= DELAY then ShowFriends() end
end)


local orig = ShowFriends
ShowFriends = function(...)
	elapsed, dirty = 0, false
	return orig(...)
end


----------------------
--      Enable      --
----------------------

function f:PLAYER_LOGIN()
	LibStub("tekKonfig-AboutPanel").new(nil, "picoFriends")

	self:RegisterEvent("FRIENDLIST_UPDATE")
	self:RegisterEvent("CHAT_MSG_SYSTEM")

	self:Show()
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
		local name, level, class, area, connected, status, note = GetFriendInfo(i)

		if name then
			if not friends[name] then friends[name] = {} end
			total = total + 1

			local t = friends[name]
			t.uid, t.level, t.class, t.area, t.status, t.connected, t.note = uid, level, class, area, status, connected, note
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

local tip = LibStub("tektip-1.0").new(4, "LEFT", "LEFT", "LEFT", "RIGHT")
function dataobj.OnLeave() tip:Hide() end
function dataobj.OnEnter(self)
	local mylevel = UnitLevel("player")

	tip:AnchorTo(self)

	tip:AddLine("picoFriends")
	tip:AddLine(" ")

	local online
	for name,data in pairs(friends) do
		if data.connected then
			online = true
			local levelr, levelg, levelb = 0, 1, 0
			if data.level < (mylevel - 5) then levelr, levelg, levelb = .6, .6, .6
			elseif data.level > (mylevel + 5) then levelr, levelg, levelb = 1, 0, 0 end
			tip:AddMultiLine(data.level, string.format("|cff%s%s|r%s%s", colors[data.class:gsub(" ", ""):upper()] or "ffffff", name, data.status == "" and "" or " ", data.status), string.trim(data.note or ""), data.area,
				levelr,levelg,levelb, nil,nil,nil, 1,0,1, 1,1,1)
		end
	end

	if total == 0 then tip:AddLine(L["You have no friends!"])
	elseif not online then tip:AddLine(L["No Friends Online"]) end

	tip:Show()
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


-----------------------------------
--      Make rocket go now!      --
-----------------------------------

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
