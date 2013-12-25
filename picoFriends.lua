
local myname, ns = ...


----------------------------
--      Localization      --
----------------------------

ns.L = {
	offline = "has gone offline",
	online = "has come online",

	["Level"] = "Level",
	["Name"] = "Name",
	["Emo"] = "Emo",
	["No Friends Online"] = "No Friends Online",
	["You have no friends!"] = "You have no friends!",
}


-------------------------------------------
--      Namespace and all that shit      --
-------------------------------------------

ns.dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(
	"picoFriends", {
		type = "data source",
		icon = "Interface\\Addons\\picoFriends\\icon",
		text = "??/??",
})


----------------------
--      Enable      --
----------------------

function ns.OnLogin()
	ns.RegisterEvent("FRIENDLIST_UPDATE")
	ns.RegisterEvent("CHAT_MSG_SYSTEM")
	ns.RegisterEvent('BN_FRIEND_ACCOUNT_ONLINE', ns.FRIENDLIST_UPDATE)
	ns.RegisterEvent('BN_FRIEND_ACCOUNT_OFFLINE', ns.FRIENDLIST_UPDATE)
	ns.RegisterEvent('BN_FRIEND_LIST_SIZE_CHANGED', ns.FRIENDLIST_UPDATE)
	ns.RegisterEvent('BN_FRIEND_INFO_CHANGED', ns.FRIENDLIST_UPDATE)

	-- Set up the periodic refresh every 5 minutes
	-- No, I'm not passing ShowFriends directly, in case of hookers
	ns.StartRepeatingTimer(300, function() ShowFriends() end)

	-- Initialize our display and refresh data
	ns.FRIENDLIST_UPDATE()
	ShowFriends()
end


------------------------------
--      Event Handlers      --
------------------------------

function ns.CHAT_MSG_SYSTEM(event, msg)
	if string.find(msg, ns.L.online) or string.find(msg, ns.L.offline) then
		ShowFriends()
	end
end


function ns.FRIENDLIST_UPDATE()
	local bnet_total, bnet_online = BNGetNumFriends()
	local wow_total, wow_online = GetNumFriends()
	ns.dataobj.text = (bnet_total + wow_total) > 0
		and string.format("%d/%d", bnet_online + wow_online, bnet_total + wow_total)
		or ns.L["Emo"]
end
