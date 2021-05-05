
-- Add/join player to channel
beerchat.add_player_channel = function(name, channel)
	if not beerchat.playersChannels[name][channel] then
		local meta = minetest.get_player_by_name(name):get_meta()
		beerchat.playersChannels[name][channel] = "joined"
		meta:set_string("beerchat:channels", minetest.write_json(beerchat.playersChannels[name]))
	end
end

-- Remove/part player from channel
beerchat.remove_player_channel = function(name, channel)
	if beerchat.playersChannels[name][channel] then
		local meta = minetest.get_player_by_name(name):get_meta()
		beerchat.playersChannels[name][channel] = nil
		meta:set_string("beerchat:channels", minetest.write_json(beerchat.playersChannels[name]))
	end
end

-- Set active channel of player, join player to channel if not already joined
beerchat.set_player_channel = function(name, channel)
	if beerchat.currentPlayerChannel[name] ~= channel then
		beerchat.add_player_channel(name, channel)
		local meta = minetest.get_player_by_name(name):get_meta()
		beerchat.currentPlayerChannel[name] = channel
		meta:set_string("beerchat:current_channel", channel)
	end
end

beerchat.get_player_channel = function(name)
	if type(name) == "string" then
		local channel = beerchat.currentPlayerChannel[name]
		if channel and beerchat.channels[channel] then
			return channel
		end
	end
end

beerchat.fix_player_channel = function(name, notify)
	if notify or notify == nil then
		minetest.chat_send_player(
			name,
			"Channel "..beerchat.currentPlayerChannel[name].." does not exist, switching back to "..
				beerchat.main_channel_name..". Please resend your message"
		)
	end
	beerchat.currentPlayerChannel[name] = beerchat.main_channel_name
	minetest.get_player_by_name(name):get_meta():set_string("beerchat:current_channel", beerchat.main_channel_name)
end

beerchat.has_player_muted_player = function(name, other_name)
	local cb_result = beerchat.execute_callbacks('before_check_muted', name, other_name)
	if cb_result ~= nil then
		return cb_result
	end

	local player = minetest.get_player_by_name(name)
	-- check jic method is used incorrectly
	if not player then
		return true
	end

	local key = "beerchat:muted:" .. other_name
	local meta = player:get_meta()
	return "true" == meta:get_string(key)
end

beerchat.is_player_subscribed_to_channel = function(name, channel)
	return (nil ~= beerchat.playersChannels[name])
		and (nil ~= beerchat.playersChannels[name][channel])
end

beerchat.send_message = function(name, message, channel)
	if not beerchat.execute_callbacks('before_send', name, message, channel) then
		return
	end

	minetest.chat_send_player(name, message)
	-- TODO: read player settings for channel sounds
	if beerchat.enable_sounds and channel ~= beerchat.main_channel_name then
		minetest.sound_play(
			beerchat.channel_message_sound, {
				to_player = name,
				gain = beerchat.sounds_default_gain
			},
			true
		)
	end
end
