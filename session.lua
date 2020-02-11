

minetest.register_on_joinplayer(function(player)

	local name = player:get_player_name()
	local meta = player:get_meta()

	local str = meta:get_string("beerchat:channels")
	if str and str ~= "" then
		beerchat.playersChannels[name] = minetest.parse_json(str) or {}
	else
		beerchat.playersChannels[name] = {}
		beerchat.playersChannels[name][beerchat.main_channel_name] = "joined"
		meta:set_string("beerchat:channels", minetest.write_json(beerchat.playersChannels[name]))
	end

	local current_channel = meta:get_string("beerchat:current_channel")
	if current_channel and current_channel ~= "" then
		beerchat.currentPlayerChannel[name] = current_channel
	else
		beerchat.currentPlayerChannel[name] = beerchat.main_channel_name
	end
	
	local jailed = meta:get_int("beerchat:jailed")
	if jailed then
		beerchat.jail_list[name] = true
		beerchat.currentPlayerChannel[name] = beerchat.jail_channel_name
		beerchat.playersChannels[name][beerchat.jail_channel_name] = "joined"
	else
		beerchat.jail_list[name] = nil
	end

end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	beerchat.playersChannels[name] = nil
	atchat_lastrecv[name] = nil
	beerchat.currentPlayerChannel[name] = nil
	beerchat.jail_list[name] = nil
end)

