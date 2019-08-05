local private_message_string = "[PM] from (${from_player}) ${message}"
local self_message_string = "(${from_player} utters to him/ herself) ${message}"
local private_message_sent_string = "[PM] sent to @(${to_player}) ${message}"

local private_message_sound = "beerchat_chime"		-- Sound when you receive a private message
local self_message_sound = "beerchat_utter"			-- Sound when you send a private message to yourself

-- @ chat a.k.a. at chat/ PM chat code, to PM players using @player1 only you can read this player1!!
atchat_lastrecv = {}

minetest.register_on_chat_message(function(name, message)
	minetest.log("action", "CHAT " .. name .. ": " .. message)
	local players, msg = string.match(message, "^@([^%s:]*)[%s:](.*)")
	if players and msg then
		if msg == "" then
			minetest.chat_send_player(name, "Please enter the private message you would like to send")
		else
			if players == "" then--reply
				-- We need to get the target
				players = atchat_lastrecv[name]
			end
			if players and players ~= "" then
				local atleastonesent = false
				local successplayers = ""
				for target in string.gmatch(","..players..",", ",([^,]+),") do
					-- Checking if the target exists
					if not minetest.get_player_by_name(target) then
						minetest.chat_send_player(name, ""..target.." is not online")
					else
						if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
							if target ~= name then
								-- Sending the message
								minetest.chat_send_player(
									target,
									beerchat.format_message(
										private_message_string, {
											from_player = name,
											message = msg
										}
									)
								)

								if beerchat.enable_sounds then
									minetest.sound_play(private_message_sound, { to_player = target, gain = 1.0 } )
								end
							else
								minetest.chat_send_player(
									target,
									beerchat.format_message(
										self_message_string, {
											from_player = name,
											message = msg
										}
									)
								)

								if beerchat.enable_sounds then
									minetest.sound_play(self_message_sound, { to_player = target, gain = 1.0 } )
								end
							end
						end
						atleastonesent = true
						successplayers = successplayers..target..","
					end
				end
				-- Register the chat in the target persons last spoken to table
				atchat_lastrecv[name] = players
				if atleastonesent then
					successplayers = successplayers:sub(1, -2)
					if (successplayers ~= name) then
						minetest.chat_send_player(
							name,
							beerchat.format_message(
								private_message_sent_string, {
									to_player = successplayers,
									message = msg
								}
							)
						)
					end
				end
			else
				minetest.chat_send_player(name, "You have not sent private messages to anyone yet, " ..
					"please specify player names to send message to")
			end
		end
		return true
	end
end)

local send_pm = function(players, name, msg)
	local atleastonesent = false
	local successplayers = ""
	for target in string.gmatch(","..players..",", ",([^,]+),") do
		-- Checking if the target exists
		if not minetest.get_player_by_name(target) then
			minetest.chat_send_player(name, ""..target.." is not online")
		else
			if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
				if target ~= name then
					-- Sending the message
					minetest.chat_send_player(
						target,
						beerchat.format_message(
							private_message_string, {
								from_player = name,
								message = msg
							}
						)
					)

					if beerchat.enable_sounds then
						minetest.sound_play(private_message_sound, { to_player = target, gain = 1.0 } )
					end
				else
					minetest.chat_send_player(
						target,
						beerchat.format_message(
							self_message_string, {
								from_player = name,
								message = msg
							}
						)
					)
					if beerchat.enable_sounds then
						minetest.sound_play(self_message_sound, { to_player = target, gain = 1.0 } )
					end
				end
			end
			atleastonesent = true
			successplayers = successplayers..target..","
		end
	end
	-- Register the chat in the target persons last spoken to table
	atchat_lastrecv[name] = players
	if atleastonesent then
		successplayers = successplayers:sub(1, -2)
		if (successplayers ~= name) then
			minetest.chat_send_player(
				name,
				beerchat.format_message(private_message_sent_string, { to_player = successplayers, message = msg })
			)
		end
	end

end

local msg_override = {
	params = "<Player Name> <Message>",
	description = "Send private message to player, "..
				"for compatibility with the old chat command but with new style chat muting support "..
				  "(players will not receive your message if they muted you) and multiple (comma separated) player support",
	func = function(name, param)
		minetest.log("action", "PM " .. name .. ": " .. param)
		local players, msg = string.match(param, "^(.-) (.*)")
		if players and msg then
			if players == "" then
				minetest.chat_send_player(name, "ERROR: Please enter the private message you would like to send")
				return false
			elseif msg == "" then
				minetest.chat_send_player(name, "ERROR: Please enter the private message you would like to send")
				return false
			else
				if players and players ~= "" then
					send_pm(players, name, msg)
				end
			end
			return true
		end
	end
}

minetest.register_chatcommand("msg", msg_override)
