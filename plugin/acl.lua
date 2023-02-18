--luacheck: no_unused_args

-- Event handler priority for ACL related hooks, could be made configurable if needed.
-- ACLs should not modify request data but should have lower priority than handlers
-- which might affect request data, for example alias plugin which can rewrite channels.
-- Important predefined priority levels are: high=0, medium=250, default=500
local PRIORITY = 50

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
-- Load player identity provider, also used as a default provider
--

acls:register_provider("*", dofile(srcdir .. "/players.lua"))

--
-- Load privilege identity provider
--

acls:register_provider("$", dofile(srcdir .. "/privileges.lua"))

--
-- Access level / authorization checks for player actions
--

beerchat.register_callback('before_join', function(name, _, data)
	return password_protected_join(name, data)
end, PRIORITY)

beerchat.register_callback('before_join', function(name, _, data)
	return acls:check_access(data.channel, name)
end, PRIORITY)

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
end, PRIORITY)

beerchat.register_callback('before_invite', function(name, data)
	-- Check if name is allowed to invite others to target channel
	if data.role == "owner" or data.role == "manager" then
		return acls:check_access(data.channel, name, "owner")
	end
	return acls:check_access(data.channel, name, "manager")
end, PRIORITY)

beerchat.register_callback("before_send", function(name, msg, data)
	-- Check if name is allowed to receive messages on target channel.
	-- Result is used to strip out second return value which is error message that
	-- would be delivered to each player who joided the channel without read access.
	local result = acls:check_access(data.channel, name, "read", "read")
	return result
end, PRIORITY)

beerchat.register_callback("before_send_on_channel", function(name, msg)
	-- Check if name is allowed to send messages on target channel
	return acls:check_access(msg.channel, name, "write", "write")
end, PRIORITY)

beerchat.register_callback('before_switch_chan', function(name, switch)
	return acls:check_access(switch.to, name)
end, PRIORITY)

beerchat.register_callback('on_forced_join', function(name, target, channel, from_channel)
	-- INJECT EVERYTHING THAT IS REQUIRED TO HAVE FULL ACCESS TO CHANNEL SO THAT
	-- PLAYERS WITH THE FORCE CAN MOVE ANYONE TO ANY CHANNEL, ALSO TO LOCKED CHANNELS.
end)
