
local myname, ns = ...


----------------------------
--      Localization      --
----------------------------

local L = {
	offline = "has gone offline",
	online = "has come online",

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
for class,c in pairs(RAID_CLASS_COLORS) do
	colors[class] = string.format("%02x%02x%02x", c.r*255, c.g*255, c.b*255)
end


-------------------------------------------
--      Namespace and all that shit      --
-------------------------------------------

local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(
	"picoFriends", {
		type = "data source",
		icon = "Interface\\Addons\\picoFriends\\icon",
		text = "??/??",
})


----------------------
--      Enable      --
----------------------

function ns.OnLogin()
	LibStub("tekKonfig-AboutPanel").new(nil, "picoFriends")

	ns.RegisterEvent("FRIENDLIST_UPDATE")
	ns.RegisterEvent("CHAT_MSG_SYSTEM")

	-- Set up the periodic refresh every 5 minutes
	-- No, I'm not passing ShowFriends directly, in case of hookers
	ns.StartRepeatingTimer(300, function() ShowFriends() end)

	-- Initialize our display and refresh data
	ns.RefreshSummary()
	ShowFriends()
end


------------------------------
--      Event Handlers      --
------------------------------

function ns.CHAT_MSG_SYSTEM(event, msg)
	if string.find(msg, L.online) or string.find(msg, L.offline) then
		ShowFriends()
	end
end


function ns.FRIENDLIST_UPDATE()
	local online = 0
	total = 0

	local uid = GetTime()
	for i = 1,GetNumFriends() do
		local name, level, class, area, connected, status, note = GetFriendInfo(i)

		if name then
			if not friends[name] then friends[name] = {} end
			total = total + 1

			local t = friends[name]
			t.uid, t.level, t.class, t.area, t.status, t.connected, t.note
				= uid, level, class, area, status, connected, note

			if connected then online = online + 1 end
		end
	end

	-- Purge out deleted friends
	for name,data in pairs(friends) do
		if data.uid ~= uid then friends[name] = nil end
	end

	ns.RefreshSummary()
end


function ns.RefreshSummary()
	local bnet_total, bnet_online = BNGetNumFriends()
	local wow_total, wow_online = GetNumFriends()
	dataobj.text = (bnet_total + wow_total) > 0
		and string.format("%d/%d", bnet_online + wow_online, bnet_total + wow_total)
		or L["Emo"]
end


------------------------
--      Tooltip!      --
------------------------

local tip = LibStub("tektip-1.0").new(4, "LEFT", "LEFT", "LEFT", "RIGHT")

local function AddDetailedLine(mylevel, level, class, name, status, note, area)
	class = class or ""
	status = status or ""
	area = area or ""
	local levelr, levelg, levelb = .5, 1, .5
	if not level then levelr, levelg, levelb = 1, 1, 1
	elseif level < (mylevel - 5) then levelr, levelg, levelb = .6, .6, .6
	elseif level > (mylevel + 5) then levelr, levelg, levelb = 1, .5, .5 end
	tip:AddMultiLine(
		level or "",
		string.format(
			"|cff%s%s|r%s%s",
			colors[class:gsub(" ", ""):upper()] or "ffffff",
			name,
			status == "" and "" or " ",
			status
		),
		string.trim(note or ""),
		area,
		levelr,levelg,levelb,
		nil,nil,nil,
		1,.5,1,
		1,1,1)
end

local myfac = UnitFactionGroup("player")
local factiontags = {
	Horde    = myfac == "Alliance" and " |cffc41e3aH|r" or "",
	Alliance = myfac ~= "Alliance" and " |cff0070ddA|r" or "",
}
local client_icons = {
	[BNET_CLIENT_WOW] = "Interface\\FriendsFrame\\Battlenet-WoWicon",
	[BNET_CLIENT_SC2] = "Interface\\FriendsFrame\\Battlenet-Sc2icon",
	[BNET_CLIENT_D3]  = "Interface\\FriendsFrame\\Battlenet-D3icon",
}
function dataobj.OnLeave() tip:Hide() end
function dataobj.OnEnter(self)
	local mylevel = UnitLevel("player")

	tip:AnchorTo(self)

	tip:AddLine("picoFriends")
	tip:AddLine(" ")

	local bnet_total, bnet_online = BNGetNumFriends()
	local wow_total, wow_online = GetNumFriends()

	for i=1,bnet_online do
		local presenceID, presenceName, battleTag, isBattleTagPresence, toonName,
		      toonID, client, online, lastOnline, isAFK, isDND, broadcastText, note,
		      isFriend, broadcastTime = BNGetFriendInfo(i)
		note = note ~= "" and note

		if online and toonID then
			local hasFocus, toonName, client, realmName, realmID, faction, race,
			      class, guild, area, level, gameText = BNGetToonInfo(toonID)
			gameText = gameText..
			           (factiontags[faction] or "")..
			           (client_icons[client] and
			           	 (" |T"..client_icons[client]..":0:0:0:0:64:64:4:60:4:60|t")
			           	 or (" ["..client.."]"))

			AddDetailedLine(mylevel, tonumber(level), class or "", toonName,
				              status or "", note or presenceName, gameText)
		elseif online then
			tip:AddMultiLine(presenceName, client, "", nil,nil,nil , nil,nil,nil,
				               1,0,1, 1,1,1)
		end
	end

	for name,data in pairs(friends) do
		if data.connected then
			AddDetailedLine(mylevel, data.level, data.class, name, data.status,
				              data.note, data.area)
		end
	end

	if (bnet_total + wow_total) == 0 then tip:AddLine(L["You have no friends!"])
	elseif (bnet_online + wow_online) == 0 then
		tip:AddLine(L["No Friends Online"])
	end

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
