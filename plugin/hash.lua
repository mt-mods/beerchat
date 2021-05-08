
-- # chat a.k.a. hash chat/ channel chat code, to send messages in chat channels using #
-- e.g. #my channel: hello everyone in my channel!
local hashchat_lastrecv = {}

beerchat.register_on_chat_message(function(name, message)

	local channel_name, msg = string.match(message, "^#(.-): (.*)")
	if not beerchat.channels[channel_name] then
		channel_name, msg = string.match(message, "^#(.-) (.*)")
	end
	if channel_name == "" then
		channel_name = hashchat_lastrecv[name]
	end

	if channel_name and msg then
		if not beerchat.execute_callbacks('before_send', name, msg, channel_name) then
			return false
		end
		if not beerchat.channels[channel_name] then
			minetest.chat_send_player(name, "Channel " .. channel_name
				.. " does not exist. Make sure the channel still "
				.. "exists and you format its name properly, e.g. #channel message "
				.. "or #my channel: message")
		elseif msg == "" then
			minetest.chat_send_player(name, "Please enter the message you would like to "
				.. "send to the channel")
		elseif not beerchat.is_player_subscribed_to_channel(name, channel_name) then
			minetest.chat_send_player(name, "You need to join this channel in order to "
				.. "be able to send messages to it")
		else
			if channel_name == "" then--use last used channel
				-- We need to get the target
				channel_name = hashchat_lastrecv[name]
			end
			if channel_name and channel_name ~= "" then
				beerchat.on_channel_message(channel_name, name, msg)
				beerchat.send_on_channel(name, channel_name, msg)
			else
				return false
			end
		end
		return true
	else
		channel_name = string.match(message, "^#(.*)")
		if channel_name then
			if not beerchat.channels[channel_name] then
				minetest.chat_send_player(name, "Channel " .. channel_name
					.. " does not exist")
			elseif not beerchat.is_player_subscribed_to_channel(name, channel_name) then
				minetest.chat_send_player(name, "You need to join this channel in order "
					.. "to be able to switch to it")
			else
				if not beerchat.execute_callbacks('before_switch_chan', name,
					beerchat.currentPlayerChannel[name], channel_name) then
					return false
				end
				beerchat.set_player_channel(name, channel_name)
				if channel_name == beerchat.main_channel_name then
					minetest.chat_send_player(
						name,
						"Switched to channel " .. channel_name
						.. ", messages will now be sent to this channel"
					)
				else
					minetest.chat_send_player(
						name,
						"Switched to channel " .. channel_name
						.. ", messages will now be sent to this channel. To switch back "
						.. "to the main channel, type #" .. beerchat.main_channel_name
					)
				end

				if beerchat.enable_sounds then
					minetest.sound_play(beerchat.channel_management_sound, {
						to_player = name, gain = beerchat.sounds_default_gain })
				end
			end
			return true
		end
		return false
	end
end)
