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
	local msg = {name=name, channel=channel_name,message=message}
	for _,player in ipairs(minetest.get_connected_players()) do
		local target = player:get_player_name()
		-- Checking if the target is in this channel
		if beerchat.execute_callbacks('on_send_on_channel', msg, target) then
			beerchat.send_message(
				target,
				beerchat.format_message(
					beerchat.main_channel_message_string, {
						channel_name = msg.channel,
						to_player = target,
						from_player = msg.name,
						message = msg.message
					}
				),
				msg.channel
			)
		end
	end
end

beerchat.register_callback("on_send_on_channel", function(msg, target)
	if not beerchat.is_player_subscribed_to_channel(target, msg.channel)
		or beerchat.has_player_muted_player(target, msg.name) then
		return false
	end
end)

minetest.register_on_chat_message(function(name, message)

	local msg_data = {name=name,message=message}
	if beerchat.execute_callbacks('on_receive', msg_data) then
		message = msg_data.message
	else
		return false
	end

	local channel_name = beerchat.currentPlayerChannel[name]

	if not minetest.check_player_privs(name, "shout") then
		-- the player does not have the shout priv, skip processing to channels
		return false -- mark as "not handled"
	end

	if not beerchat.channels[channel_name] then
		minetest.chat_send_player(
			name,
			"Channel "..channel_name.." does not exist, switching back to "..
				beerchat.main_channel_name..". Please resend your message"
		)
		beerchat.currentPlayerChannel[name] = beerchat.main_channel_name
		minetest.get_player_by_name(name):get_meta():set_string(
			"beerchat:current_channel", beerchat.main_channel_name)
		return true
	end

	if not beerchat.channels[channel_name] then
		minetest.chat_send_player(name, "Channel "..channel_name.." does not exist")
	elseif message == "" then
		minetest.chat_send_player(name,
			"Please enter the message you would like to send to the channel")
	elseif not beerchat.is_player_subscribed_to_channel(name, channel_name) then
		minetest.chat_send_player(name,
			"You need to join this channel in order to be able to send messages to it")
	else
		beerchat.on_channel_message(channel_name, name, message)
		beerchat.send_on_channel(name, channel_name, message)
	end
	return true
end)
