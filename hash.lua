
local channel_message_string = "|#${channel_name}| <${from_player}> ${message}"

-- # chat a.k.a. hash chat/ channel chat code, to send messages in chat channels using # e.g. #my channel: hello everyone in my channel!
hashchat_lastrecv = {}

minetest.register_on_chat_message(function(name, message)
	local channel_name, msg = string.match(message, "^#(.-): (.*)")
	if not beerchat.channels[channel_name] then
		channel_name, msg = string.match(message, "^#(.-) (.*)")
	end
	if channel_name == "" then
		channel_name = hashchat_lastrecv[name]
	end

	if channel_name and msg then
		if not beerchat.channels[channel_name] then
			minetest.chat_send_player(name, "Channel "..channel_name.." does not exist. Make sure the channel still "..
											"exists and you format its name properly, e.g. #channel message or #my channel: message")
		elseif msg == "" then
			minetest.chat_send_player(name, "Please enter the message you would like to send to the channel")
		elseif not beerchat.playersChannels[name][channel_name] then
			minetest.chat_send_player(name, "You need to join this channel in order to be able to send messages to it")
		else
			if channel_name == "" then--use last used channel
				-- We need to get the target
				channel_name = hashchat_lastrecv[name]
			end
			if channel_name and channel_name ~= "" then
				for _,player in ipairs(minetest.get_connected_players()) do
					local target = player:get_player_name()
					-- Checking if the target is in this channel
					if  beerchat.playersChannels[target] and beerchat.playersChannels[target][channel_name] then
						if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
							if channel_name == beerchat.main_channel_name then
								minetest.chat_send_player(target, format_message(beerchat.main_channel_message_string, { channel_name = channel_name, from_player = name, message = msg }))
							else
								minetest.chat_send_player(target, format_message(channel_message_string, { channel_name = channel_name, from_player = name, message = msg }))
								if beerchat.enable_sounds then
									minetest.sound_play(beerchat.channel_message_sound, { to_player = target, gain = 1.0 } )
								end
							end
						end
					end
				end
				-- Register the chat in the target persons last spoken to table
				hashchat_lastrecv[name] = channel_name
			else
				return false
			end
		end
		return true
	else
		channel_name = string.match(message, "^#(.*)")
		if channel_name then
			if not beerchat.channels[channel_name] then
				minetest.chat_send_player(name, "Channel "..channel_name.." does not exist")
			elseif not beerchat.playersChannels[name][channel_name] then
				minetest.chat_send_player(name, "You need to join this channel in order to be able to switch to it")
			else
				beerchat.currentPlayerChannel[name] = channel_name
				minetest.get_player_by_name(name):set_attribute("beerchat:current_channel", channel_name)
				if channel_name == beerchat.main_channel_name then
					minetest.chat_send_player(name, "Switched to channel "..channel_name..", messages will now be sent to this channel")
				else
					minetest.chat_send_player(name, "Switched to channel "..channel_name..", messages will now be sent to this channel. To switch back "..
													"to the main channel, type #"..beerchat.main_channel_name)
				end

				if beerchat.enable_sounds then
					minetest.sound_play(beerchat.channel_management_sound, { to_player = name, gain = 1.0 } )
				end
			end
			return true
		end
	end
end)

