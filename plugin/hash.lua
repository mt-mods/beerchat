
-- # chat a.k.a. hash chat/ channel chat code, to send messages in chat channels using #
-- e.g. #my-channel: hello everyone in my channel!

local function switch_channel(name, channel)
	local skip_sound
	if not beerchat.is_player_subscribed_to_channel(name, channel) then
		if beerchat.channels[channel].password and beerchat.channels[channel].password ~= "" then
			minetest.chat_send_player(name, "Channel is protected, you need to join this channel with /jc command")
			return
		elseif not beerchat.join_channel(name, channel) then
			return
		end
		-- Skip channel switch sound because beerchat.join_channel will also play sound
		skip_sound = true
	end
	if not beerchat.execute_callbacks('before_switch_chan', name,
		beerchat.currentPlayerChannel[name], channel) then
		return
	end
	beerchat.set_player_channel(name, channel)
	if channel == beerchat.main_channel_name then
		minetest.chat_send_player(name,
			"Switched to channel " .. channel .. ", messages will now be sent to this channel"
		)
	else
		minetest.chat_send_player(name,
			"Switched to channel " .. channel .. ", messages will now be sent to this channel. "
			.. "To switch back to the main channel, type #" .. beerchat.main_channel_name
		)
	end
	if not skip_sound and beerchat.enable_sounds then
		minetest.sound_play(
			beerchat.channel_management_sound,
			{
				to_player = name,
				gain = beerchat.sounds_default_gain
			}
		)
	end
end

beerchat.register_on_chat_message(function(name, message)
	local channel_name, msg = string.match(message, "^#(%S+) ?(.*)")

	if not channel_name then
		return false
	elseif not beerchat.channels[channel_name] then
		minetest.chat_send_player(name,
			"Channel " .. channel_name .. " does not exist. Make sure the channel still exists "
			.. "and you format its name properly, e.g. #channel message"
		)
	elseif msg == "" then
		switch_channel(name, channel_name)
	elseif not beerchat.is_player_subscribed_to_channel(name, channel_name) then
		minetest.chat_send_player(name, "You need to join this channel in order to be able to send messages to it")
	else
		beerchat.on_channel_message(channel_name, name, msg)
		beerchat.send_on_channel(name, channel_name, msg)
	end

	return true
end)
