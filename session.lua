

minetest.register_on_joinplayer(function(player)
	local str = player:get_attribute("beerchat:channels")
	if str and str ~= "" then
		beerchat.playersChannels[player:get_player_name()] = {}
		beerchat.playersChannels[player:get_player_name()] = minetest.parse_json(str) or {}
	else
		beerchat.playersChannels[player:get_player_name()] = {}
		beerchat.playersChannels[player:get_player_name()][beerchat.main_channel_name] = "joined"
		player:set_attribute("beerchat:channels", minetest.write_json(beerchat.playersChannels[player:get_player_name()]))
	end

	local current_channel = player:get_attribute("beerchat:current_channel")
	if current_channel and current_channel ~= "" then
		beerchat.currentPlayerChannel[player:get_player_name()] = current_channel
	else
		beerchat.currentPlayerChannel[player:get_player_name()] = beerchat.main_channel_name
	end

end)

minetest.register_on_leaveplayer(function(player)
	beerchat.playersChannels[player:get_player_name()] = nil
	atchat_lastrecv[player:get_player_name()] = nil
	beerchat.currentPlayerChannel[player:get_player_name()] = nil
end)
