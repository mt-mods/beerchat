
local http = beerchat.http

beerchat.on_channel_message = function(channel, playername, message)

	local data = {
		channel = channel,
		username = playername,
		message = message
	}

	local json = minetest.write_json(data)

	http.fetch({
		url = beerchat.url,
		extra_headers = { "Content-Type: application/json" },
		timeout = 5,
		post_data = json
	}, function()
		-- ignore errors
	end)

end

-- join player message
minetest.register_on_joinplayer(function(player)
	beerchat.on_channel_message(nil, nil, "Player " .. player:get_player_name() ..
		" joined the game")
end)

-- leave player message
minetest.register_on_leaveplayer(function(player, timed_out)
	local msg = player:get_player_name() .. " left the game"
	if timed_out then
		msg = msg .. " (timed out)"
	end

	beerchat.on_channel_message(nil, nil, msg)
end)

-- initial message on start
beerchat.on_channel_message(nil, nil, "Minetest started!")

minetest.register_on_shutdown(function()
	beerchat.on_channel_message(nil, nil, "Minetest shutting down!")
end)

-- auth fail
minetest.register_on_auth_fail(function(name, ip)
	beerchat.on_channel_message("audit", nil, "Player '" .. name ..
		"' from ip " .. ip .. " tried to connect with wrong password")
end)

-- anticheat
minetest.register_on_cheat(function(player, cheat)
	local playername = player:get_player_name()
	local type = cheat.type
	beerchat.on_channel_message("audit", nil, "Player '" .. playername ..
		"' triggered anticheat: '" .. (type or "<unknown>") ..
		"' at position: " .. minetest.pos_to_string(vector.floor(player:get_pos())))
end)
