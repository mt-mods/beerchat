--
-- Adds chat command /force2channel <Channel Name>, <Player Name>
-- Command requires ban privilege.
--

beerchat.force_player_to_channel = function(name, param)
	if not param or param == "" then
		return false, "ERROR: Invalid number of arguments. Please supply the "
			.. "channel name and the player name."
	end

	local channel_name, player_name = string.match(param, "(.*), ?(.*)")

	if not channel_name or channel_name == "" then
		return false, "ERROR: Channel name is empty."
	end

	if not player_name or player_name == "" then
		return false, "ERROR: Player name not supplied or empty."
	end

	if not beerchat.channels[channel_name] then
		return false, "ERROR: Channel " .. channel_name .. " does not exist."
	end

	if not minetest.get_player_by_name(player_name) then
		return false, "ERROR: " .. player_name .. " does not exist or is not online."
	else
		local from_channel = beerchat.get_player_channel(player_name) or beerchat.main_channel_name
		-- force join and set default channel
		beerchat.set_player_channel(player_name, channel_name)
		-- execute callbacks after action
		beerchat.execute_callbacks('on_forced_join', name, player_name, channel_name, from_channel)
	end
	return true
end

minetest.register_chatcommand("force2channel", {
	params = "<Channel Name>, <Player Name>",
	description = "Force player named <Player Name> to channel named <Channel Name>. Requires ban privilege.",
	privs = { ban = true },
	func = beerchat.force_player_to_channel
})
