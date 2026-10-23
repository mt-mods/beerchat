-- auth fail
core.register_on_authplayer(function(name, ip, is_success)
	if not is_success then
		beerchat.on_channel_message(
			"audit",
			"SYSTEM",
			"Player '" .. name .. "' from ip " .. ip .. " tried to connect with wrong password"
		)
	end
end)

-- anticheat
core.register_on_cheat(function(player, cheat)
	local playername = player:get_player_name()
	local type = cheat.type
	beerchat.on_channel_message(
		"audit",
		"SYSTEM",
		"Player '"
			.. playername
			.. "' triggered anticheat: '"
			.. (type or "<unknown>")
			.. "' at position: "
			.. core.pos_to_string(vector.floor(player:get_pos()))
	)
end)
