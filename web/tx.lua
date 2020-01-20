
local http = beerchat.http

beerchat.on_channel_message = function(channel, playername, message)

	local data = {
		source_system = "minetest",
		source_channel = channel,
		target = playername,
		message = message
	}

	local json = minetest.write_json(data)

	http.fetch({
		url = beerchat.url,
		extra_headers = { "Content-Type: application/json" },
		timeout = 5,
		post_data = json
	}, function(res)
		-- ignore errors
	end)

end

minetest.register_on_joinplayer(function(player)
	beerchat.on_channel_message(nil, nil, "Player " .. player:get_player_name() ..
		" joined the game")
end)

minetest.register_on_leaveplayer(function(player, timed_out)

	local msg = player:get_player_name() .. " left the game"
	if timed_out then
		msg = msg .. " (timed out)"
	end

	beerchat.on_channel_message(nil, nil, msg)
end)

beerchat.on_channel_message(nil, nil, "Minetest started!")
