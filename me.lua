
local me_message_string = "|#${channel_name}| * ${from_player} ${message}"

local me_override = {
	params = "<Message>",
	description = "Send message in the \"* player message\" format, e.g. /me eats pizza becomes |#"..beerchat.main_channel_name.."| * Player01 eats pizza",
	func = function(name, param)
		local msg = param
		local channel_name = beerchat.main_channel_name
		if not beerchat.channels[channel_name] then
			minetest.chat_send_player(name, "Channel "..channel_name.." does not exist")
		elseif msg == "" then
			minetest.chat_send_player(name, "Please enter the message you would like to send to the channel")
		elseif not beerchat.playersChannels[name][channel_name] then
			minetest.chat_send_player(name, "You need to join this channel in order to be able to send messages to it")
		else
			for _,player in ipairs(minetest.get_connected_players()) do
				local target = player:get_player_name()
				-- Checking if the target is in this channel
				if beerchat.playersChannels[target] and beerchat.playersChannels[target][channel_name] then
					if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
						minetest.chat_send_player(target, format_message(me_message_string, { channel_name = channel_name, from_player = name, message = msg }))
					end
				end
			end
		end
		return true
	end
}

minetest.register_chatcommand("me", me_override)

