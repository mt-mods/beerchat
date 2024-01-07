-- Channel password handler
--

local function protected_join(name, password, data)
	if type(data) ~= "table" or type(data.channel) ~= "string" or data.channel == "" then
		minetest.log("warning", "Invalid password_requests data for player '" .. name .. "'")
		minetest.chat_send_player(name, "ERROR: Something went wrong with authorization, please try joining again.")
		return
	end
	local channel = beerchat.channels[data.channel]
	if type(channel) ~= "table" then
		minetest.chat_send_player(name, "ERROR: Channel #"..data.channel.." disappeared while joining.")
		return
	end
	if password == channel.password then
		minetest.chat_send_player(name, "OK: Channel #"..data.channel.." password accepted.")
		;(data.set_default and beerchat.set_player_channel or beerchat.add_player_channel)(name, data.channel)
	else
		minetest.chat_send_player(name, "ERROR: Invalid password, please verify password and try joining again.")
	end
end

return function(name, data)
	local channel = beerchat.channels[data.channel]
	if channel and channel.password and channel.password ~= "" then
		if not data or not data.password or data.password == "" then
			-- Channel has password but nothing has provided any password so far, ask player to provide password
			beerchat.capture_message(name, function(playername, password)
				protected_join(playername, password, { channel = data.channel, set_default = data.set_default })
			end)
			return false, minetest.colorize("#f00d00", "ATTENTION:") .. "This channel requires that you supply"
				.. " a password. Your next message will be used as a password and hidden from other players.\n"
				.. minetest.colorize("#f00d00", "Please enter your password:")
		end
		-- External password handling mechanism has already provided password for this channel, verify it
		if data.password ~= channel.password then
			return false, "ERROR: Invalid password."
		end
	end
end
