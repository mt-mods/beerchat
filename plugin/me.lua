
local me_message_string = "|#${channel_name}| * ${from_player} ${message}"

local me_override = {
	params = "<Message>",
	description = "Send message in the \"* player message\" format, e.g. /me eats pizza becomes |#"..
		beerchat.main_channel_name.."| * Player01 eats pizza",
	func = function(name, param)
		local msg = param
		local channel = beerchat.get_player_channel(name)
		if not channel then
			beerchat.fix_player_channel(name, true)
		elseif not beerchat.channels[channel] then
			minetest.chat_send_player(name, "Channel "..channel.." does not exist.")
		elseif msg == "" then
			minetest.chat_send_player(name, "Please enter the message you would like to send.")
		elseif not beerchat.playersChannels[name][channel] then
			minetest.chat_send_player(name, "You need to join channel " .. channel
				.. " in order to be able to send messages to it")
		else
			local cb_result, cb_message = beerchat.execute_callbacks('before_send_me', name, msg, channel)
			beerchat.on_me_message(channel, name, msg)
			if not cb_result then
				if cb_message then return false, cb_message else return false end
			end
			for _,player in ipairs(minetest.get_connected_players()) do
				local target = player:get_player_name()
				-- Checking if the target is in this channel
				if beerchat.is_player_subscribed_to_channel(target, channel) then
					if not beerchat.has_player_muted_player(target, name) then
						beerchat.send_message(
							target,
							beerchat.format_message(me_message_string, {
								to_player = target,
								channel_name = channel,
								from_player = name,
								message = msg
							}),
							channel
						)
					end
				end
			end
		end
		return true
	end
}

minetest.register_chatcommand("me", me_override)
