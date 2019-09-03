



-- Message string formats -- Change these if you would like different formatting
--
-- These can be changed to show "~~~#mychannel~~~ <player01> message" instead of "|#mychannel| or any
-- other format you like such as removing the channel name from the main channel, putting channel or
-- player names at the end of the chat message, etc.
--
-- The following parameters are available and can be specified :
-- ${channel_name} name of the channel
-- ${channel_owner} owner of the channel
-- ${channel_password} password to use when joining the channel, used e.g. for invites
-- ${from_player} the player that is sending the message
-- ${to_player} player to which the message is sent, will contain multiple player names
-- e.g. when sending a PM to multiple players
-- ${message} the actual message that is to be sent
-- ${time} the current time in 24 hour format, as returned from os.date("%X")
--

beerchat.send_on_channel = function(name, channel_name, message)
	for _,player in ipairs(minetest.get_connected_players()) do
		local target = player:get_player_name()
		-- Checking if the target is in this channel
		if beerchat.playersChannels[target] and beerchat.playersChannels[target][channel_name] then
			if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
				minetest.chat_send_player(
					target,
					beerchat.format_message(
						beerchat.main_channel_message_string, {
							channel_name = channel_name,
							to_player = target,
							from_player = name,
							message = message
						}
					)
				)

				if channel_name ~= beerchat.main_channel_name and beerchat.enable_sounds then
					minetest.sound_play(beerchat.channel_message_sound, { to_player = target, gain = 0.3 } )
				end
			end
		end
	end
end


minetest.register_on_chat_message(function(name, message)
	local channel_name = beerchat.currentPlayerChannel[name]

	if not beerchat.channels[channel_name] then
		minetest.chat_send_player(
			name,
			"Channel "..channel_name.." does not exist, switching back to "..
				beerchat.main_channel_name..". Please resend your message"
		)
		beerchat.currentPlayerChannel[name] = beerchat.main_channel_name
		minetest.get_player_by_name(name):set_attribute("beerchat:current_channel", beerchat.main_channel_name)
		return true
	end

	if not beerchat.channels[channel_name] then
		minetest.chat_send_player(name, "Channel "..channel_name.." does not exist")
	elseif message == "" then
		minetest.chat_send_player(name, "Please enter the message you would like to send to the channel")
	elseif beerchat.playersChannels[name] and not beerchat.playersChannels[name][channel_name] then
		minetest.chat_send_player(name, "You need to join this channel in order to be able to send messages to it")
	else
		beerchat.on_channel_message(channel_name, name, message)
		beerchat.send_on_channel(name, channel_name, message)
	end
	return true
end)
