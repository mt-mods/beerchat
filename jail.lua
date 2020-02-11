-- Jail channel is where you put annoying missbehaving users with /force2channel
beerchat.jail_channel_name = minetest.settings:get("beerchat.jail_channel_name") or "grounded"
beerchat.jail_channel_name = beerchat.jail_channel_name or "grounded"

beerchat.jail_list = {}

if nil == beerchat.jail_channel_name or "" == beerchat.jail_channel_name then
	beerchat.jail_channel_name = "wail"
end

beerchat.is_player_jailed = function(name)
	return true == beerchat.jail_list[name]
end

beerchat.register_callback('before_invite', function(sender, recipient, channel)
	if beerchat.is_player_jailed(player_name) then
		return false, player_name .. " is in chat-jail, no inviting."
	end
	return true
end)

beerchat.register_callback('before_mute', function(name, target)
	if beerchat.is_player_jailed(name) then
		return false, "You are in chat-jail, no muting for you."
	end
	return true
end)

beerchat.register_callback('before_join', function(name, channel)
	if beerchat.is_player_jailed(name) then
		return false, "You are in chat-jail, no joining channels for you."
	end
	return true
end)

beerchat.register_callback('before_leave', function(name, channel)
	if beerchat.is_player_jailed(name) then
		return false, "You are in chat-jail, no leaving for you."
	end
	return true
end)

beerchat.register_callback('on_forced_join', function(name, target, channel, target_meta)
	-- going to/from jail?
	if channel == beerchat.jail_channel_name then
		target_meta:set_int("beerchat:jailed", 1)
		beerchat.jail_list[target] = true
	elseif beerchat.is_player_jailed(target) then
		target_meta:set_int("beerchat:jailed", 0)
		beerchat.jail_list[target] = nil
	end
	return true
end)
