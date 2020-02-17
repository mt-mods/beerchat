-- Jail channel is where you put annoying missbehaving users with /force2channel
beerchat.jail = {}

-- you deserve it if you know how to install mod and deliberately misconfigure it
beerchat.jail.channel_name = minetest.settings:get("beerchat.jail.channel_name") or "grounded"
beerchat.jail.priv = minetest.settings:get("beerchat.jail.priv") or "ban"
local owner = minetest.settings:get("beerchat.jail.owner")
local color = minetest.settings:get("beerchat.jail.color")

beerchat.channels[beerchat.jail.channel_name] = {
	owner = owner or beerchat.channels[beerchat.main_channel_name].owner,
	color = color or beerchat.channels[beerchat.main_channel_name].color
}

beerchat.jail.list = {}

beerchat.is_player_jailed = function(name)
	return true == beerchat.jail.list[name]
end

beerchat.jail.handle_jail_lock = function(name, meta, jailing)
	-- going to/from jail?
	if jailing then
		meta:set_int("beerchat:jailed", 1)
		beerchat.jail.list[name] = true
	elseif beerchat.is_player_jailed(name) then
		meta:set_int("beerchat:jailed", 0)
		beerchat.jail.list[name] = nil
	end
end

beerchat.jail.chat_jail = function(name, param)
	if not param or param == "" then
		return false, "ERROR: Invalid number of arguments. Please supply the player name(s)."
	end

	if not beerchat.channels[beerchat.jail.channel_name] then
		return false, "ERROR: Channel " .. beerchat.jail.channel_name
			.. " does not exist. Someone deleted it... fix by adding "
			.. "before_delete_chan event :)"
	end

	local player_names = string.gmatch(param, "%S+")
	for player_name in player_names do
		beerchat.force_player_to_channel(name, string.format('%s, %s',
			beerchat.jail.channel_name, player_name))
	end
	return true
end
minetest.register_chatcommand("chat_jail", {
	params = "<Player Name> [<Player Name> ...]",
	description = string.format("Move players <Player Name> to jail channel. "
		.. "You must have %s priv to use this.", beerchat.jail.priv),
	privs = { [beerchat.jail.priv] = true },
	func = beerchat.jail.chat_jail
})

beerchat.jail.chat_unjail = function(name, param)
	if not param or param == "" then
		return false, "ERROR: Invalid number of arguments. Please supply the player name(s)."
	end
	local player_names = string.gmatch(param, "%S+")
	for player_name in player_names do
		local player = minetest.get_player_by_name(player_name)
		if not player then
			return false, "ERROR: " .. player_name .. " does not exist or is not online."
		else
			local meta = player:get_meta()
			beerchat.jail.handle_jail_lock(player_name, meta, false)
			-- inform user
			minetest.chat_send_player(player_name, "You have been released from chat jail. "
				.. "Use #" .. beerchat.main_channel_name .. " to get back to main channel.")
			-- feedback to mover
			minetest.chat_send_player(name, "Released " .. player_name .. " from chat jail.")
			-- inform admin
			minetest.log("action", "CHAT " .. name .. " released " .. player_name
				.. " from jail channel " .. beerchat.jail.channel_name)
		end
	end
	return true
end
minetest.register_chatcommand("chat_unjail", {
	params = "<Player Name> [<Player Name> ...]",
	description = string.format("Release players <Player Name> from jail. Players *can* "
		.. "switch channel after this. You must have %s priv to use this.",
		beerchat.jail.priv),
	privs = { [beerchat.jail.priv] = true },
	func = beerchat.jail.chat_unjail
})

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local meta = player:get_meta()

	local jailed = 1 == meta:get_int("beerchat:jailed")
	if jailed then
		beerchat.jail.list[name] = true
		beerchat.currentPlayerChannel[name] = beerchat.jail.channel_name
		beerchat.playersChannels[name][beerchat.jail.channel_name] = "joined"
	else
		beerchat.jail.list[name] = nil
	end

end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	beerchat.jail.list[name] = nil
end)

beerchat.register_callback('before_invite', function(sender, recipient, channel)
	if beerchat.is_player_jailed(player_name) then
		return false, player_name .. " is in chat-jail, no inviting."
	end
end)

beerchat.register_callback('before_mute', function(name, target)
	if beerchat.is_player_jailed(name) then
		return false, "You are in chat-jail, no muting for you."
	end
end)

beerchat.register_callback('before_join', function(name, channel)
	if beerchat.is_player_jailed(name) then
		return false, "You are in chat-jail, no joining channels for you."
	end
end)

beerchat.register_callback('before_leave', function(name, channel)
	if beerchat.is_player_jailed(name) then
		return false, "You are in chat-jail, no leaving for you."
	end
end)

beerchat.register_callback('before_send', function(name, message, channel)
	local jailed = beerchat.is_player_jailed(name)
	local is_jail_channel = channel == beerchat.jail.channel_name
	if jailed then
		if is_jail_channel then
			-- override default send method to mute pings for jailed users
			-- but allow chatting without pings on jail channel
			minetest.chat_send_player(name, message)
		end
		return false
	end
end)

beerchat.register_callback('before_switch_chan', function(name, oldchannel, newchannel)
	if beerchat.is_player_jailed(name) then
		return false
	end
end)

beerchat.register_callback('before_send_pm', function(name, message, target)
	if beerchat.is_player_jailed(name) then
		return false, "You are in chat-jail, no PMs for you."
	end
end)

beerchat.register_callback('before_send_me', function(name, message, channel)
	if beerchat.is_player_jailed(name) then
		return false, "You are in chat-jail, you may not use /me command."
	end
end)

beerchat.register_callback('before_whisper', function(name, message, channel, range)
	if beerchat.is_player_jailed(name) then
		return false
	end
end)

beerchat.register_callback('before_check_muted', function(name, muted)
	if beerchat.is_player_jailed(name) then
		return false
	end
end)

beerchat.register_callback('on_forced_join', function(name, target, channel, target_meta)
	beerchat.jail.handle_jail_lock(target, target_meta,
		channel == beerchat.jail.channel_name)
end)
