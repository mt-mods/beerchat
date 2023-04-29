
-- Add/join player to channel
beerchat.add_player_channel = function(name, channel, mode)
	if not beerchat.playersChannels[name][channel] then
		local meta = minetest.get_player_by_name(name):get_meta()
		beerchat.playersChannels[name][channel] = mode or "joined"
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
	beerchat.set_player_channel(name, beerchat.main_channel_name)
end

beerchat.join_channel = function(name, channel, set_default)
	if not beerchat.execute_callbacks('before_join', name, channel) then
		return false
	end
	(set_default and beerchat.set_player_channel or beerchat.add_player_channel)(name, channel)
	if beerchat.enable_sounds then
		minetest.sound_play("beerchat_chirp", { to_player = name, gain = beerchat.sounds_default_gain })
	end
	local msg = beerchat.format_message("|#${channel_name}| Joined channel", { channel_name = channel })
	minetest.chat_send_player(name, msg)
	return true
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

beerchat.send_message = function(name, message, data)
	if beerchat.execute_callbacks('before_send', name, message or data.message, data) then
		if type(data) == "table" then
			minetest.chat_send_player(name, data.message or message)
		else
			minetest.chat_send_player(name, message)
		end
	end
	--[[ TODO: read player settings for channel sounds, also move this from core to some sound effect extension.
	if beerchat.enable_sounds and channel ~= beerchat.main_channel_name then
		minetest.sound_play(
			beerchat.channel_message_sound, {
				to_player = name,
				gain = beerchat.sounds_default_gain
			},
			true
		)
	end --]]
end
