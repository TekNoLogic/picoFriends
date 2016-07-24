
local myname, ns = ...

local L = ns.L

local colors = {}
for class,c in pairs(RAID_CLASS_COLORS) do
	colors[class] = c.colorStr
end


local tip = ns.NewTooltip(4, "LEFT", "LEFT", "LEFT", "RIGHT")

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
			"|c%s%s|r%s%s",
			colors[class:gsub(" ", ""):upper()] or "ffffffff",
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

local factiontags = {
	Horde    = " |TInterface\\TargetingFrame\\UI-PVP-Horde:0:0:0:0:64:64:0:38:0:38|t",
	Alliance = " |TInterface\\TargetingFrame\\UI-PVP-Alliance:0:0:0:0:64:64:0:38:0:38|t",
}
function ns.dataobj.OnLeave() tip:Hide() end
function ns.dataobj.OnEnter(self)
	local mylevel = UnitLevel("player")

	tip:AnchorTo(self)

	tip:AddLine("picoFriends")
	tip:AddLine(" ")

	local bnet_total, bnet_online = BNGetNumFriends()
	local wow_total, wow_online = GetNumFriends()

	for i=1,bnet_online do
		local presenceID, presenceName, battleTag, isBattleTagPresence,
		      characterName, toonID, client, online, lastOnline, isAFK, isDND,
					broadcastText, note, isFriend, broadcastTime = BNGetFriendInfo(i)
		note = note ~= "" and note

		if online and toonID then
			local hasFocus, characterName, client, realmName, realmID, faction, race,
			      class, guild, area, level, gameText = BNGetGameAccountInfo(toonID)
			local texture = BNet_GetClientTexture(client)
			gameText = gameText..
			           (factiontags[faction] or "")..
			           (" |T"..texture..":0:0:0:0:64:64:4:60:4:60|t")

			AddDetailedLine(mylevel, tonumber(level), class or "", characterName,
				              status or "", note or presenceName, gameText)
		elseif online then
			tip:AddMultiLine(presenceName, client, "", nil,nil,nil , nil,nil,nil,
				               1,0,1, 1,1,1)
		end
	end

	for i = 1,GetNumFriends() do
		local name, level, class, area, connected, status, note = GetFriendInfo(i)
		if connected then
			AddDetailedLine(mylevel, level, class, name, status, note, area)
		end
	end

	if (bnet_total + wow_total) == 0 then tip:AddLine(ns.L["You have no friends!"])
	elseif (bnet_online + wow_online) == 0 then
		tip:AddLine(ns.L["No Friends Online"])
	end

	tip:Show()
end


------------------------------------------
--      Click to open friend panel      --
------------------------------------------

function ns.dataobj.OnClick()
	if FriendsFrame:IsVisible() then HideUIPanel(FriendsFrame)
	else
		ToggleFriendsFrame(1)
		FriendsFrame_Update()
		tip:Hide()
	end
end
