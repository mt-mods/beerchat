
local http = beerchat.http

-- normal message in chat channel
beerchat.on_channel_message = function(channel, playername, message)

	local data = {
		channel = channel,
		username = playername,
		message = message,
		type = "message"
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

-- /me message in chat channel
beerchat.on_me_message = function(channel, playername, message)
	local data = {
		channel = channel,
		username = playername,
		message = message,
		type = "me"
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

-- map to players -> new == true
local new_player_map = {}

-- check on prejoin if the player is new
minetest.register_on_prejoinplayer(function(name)
	if not minetest.player_exists(name) then
		new_player_map[name] = true
	end
end)

-- join player message
minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()

	local msg = "Player " .. playername .. " joined the game"
	if new_player_map[playername] then
		msg = msg .. " (new player)"
		-- clear new-player flag
		new_player_map[playername] = nil
	end

	beerchat.on_channel_message(nil, nil, msg)
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
