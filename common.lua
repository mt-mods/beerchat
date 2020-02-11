
beerchat.has_player_muted_player = function(name, other_name)
	-- ignore muting for jailed users
	if beerchat.is_player_jailed(name) then
		return false
	end
	local player = minetest.get_player_by_name(name)
	-- check jic method is used incorrectly
	if not player then
		return true
	end

	local key = "beerchat:muted:" .. other_name
	local meta = player:get_meta()
	return "true" == meta:get_string(key)
end -- has_player_muted_player

beerchat.is_player_subscribed_to_channel = function(name, channel)
	return (nil ~= beerchat.playersChannels[name])
		and (nil ~= beerchat.playersChannels[name][channel])
end -- is_player_subscribed_to_channel

beerchat.send_message = function(name, message, channel)
	local jailed = beerchat.is_player_jailed(name)
	local is_jail_channel = channel == beerchat.jail_channel_name
	if jailed and not is_jail_channel then
		return
	end
	minetest.chat_send_player(name, message)
	if is_jail_channel then
		return
	end
-- TODO: read player settings for channel sounds
	if beerchat.enable_sounds and channel ~= beerchat.main_channel_name then
		minetest.sound_play(beerchat.channel_message_sound, { to_player = name, gain = beerchat.sounds_default_gain } )
	end
end -- send_message

