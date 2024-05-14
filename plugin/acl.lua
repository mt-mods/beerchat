--luacheck: no_unused_args

--
-- Load ACL core functionality and ACL modules
--

local srcdir = minetest.get_modpath("beerchat").."/plugin/acl"

local acls = dofile(srcdir .. "/acls.lua")(
	minetest.deserialize(beerchat.mod_storage:get("acl.acls")),
	function (data) beerchat.mod_storage:set_string("acl.acls", minetest.serialize(data)) end
)

local password_protected_join = dofile(srcdir .. "/password.lua")

loadfile(srcdir .. "/chatcommands.lua")(acls)

--
-- Access level / authorization checks for player actions
--

beerchat.register_callback('before_join', function(name, _, data)
	return password_protected_join(name, data)
end)

beerchat.register_callback('before_join', function(name, _, data)
	return acls:check_access(data.channel, name)
end)

beerchat.register_callback('after_joinplayer', function(player)
	local name = player:get_player_name()
	if name and beerchat.playersChannels[name] then
		for channel in pairs(beerchat.playersChannels[name]) do
			local success, message = acls:check_access(channel, name)
			if success == false then
				beerchat.remove_player_channel(name, channel)
				minetest.chat_send_player(name, message)
			end
		end
	end
end)

beerchat.register_callback('before_invite', function(name, data)
	if data.role == "owner" or data.role == "manager" then
		return acls:check_access(data.channel, name, "owner")
	end
	return acls:check_access(data.channel, name, "manager")
end)

beerchat.register_callback("before_send_on_channel", function(name, msg)
	return acls:check_access(msg.channel, name, "write", "write")
end)

beerchat.register_callback('before_switch_chan', function(name, switch)
	return acls:check_access(switch.to, name)
end)

beerchat.register_callback('on_forced_join', function(name, target, channel, from_channel)
	-- INJECT EVERYTHING THAT IS REQUIRED TO HAVE FULL ACCESS TO CHANNEL SO THAT
	-- PLAYERS WITH THE FORCE CAN MOVE ANYONE TO ANY CHANNEL, ALSO TO LOCKED CHANNELS.
end)
