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

	local player = minetest.get_player_by_name(player_name)
	if not player then
		return false, "ERROR: " .. player_name .. " does not exist or is not online."
	else
		local meta = player:get_meta()
		-- force join
		beerchat.playersChannels[player_name] = beerchat.playersChannels[player_name] or {}
		beerchat.playersChannels[player_name][channel_name] = "joined"
		meta:set_string(
			"beerchat:channels",
			minetest.write_json(beerchat.playersChannels[player_name])
		)
		-- force default channel
		beerchat.currentPlayerChannel[player_name] = channel_name
		meta:set_string("beerchat:current_channel", channel_name)

		if not beerchat.execute_callbacks('on_forced_join', name, player_name, channel_name, meta) then
			return false
		end

		-- inform user
		minetest.chat_send_player(player_name, name .. " has set your default channel to "
			.. channel_name .. ".")
		-- feedback to mover
		minetest.chat_send_player(name, "Set default channel of " .. player_name
			.. " to " .. channel_name .. ".")
		-- inform moderators, if moderator channel is set
		if beerchat.moderator_channel_name then
			beerchat.send_on_channel(beerchat.channels[beerchat.main_channel_name].owner,
				beerchat.moderator_channel_name,
				name .. " has set default channel of " .. player_name .. " to "
				.. channel_name .. ".")
		end
		-- inform admin
		minetest.log("action", "CHAT " .. name .. " moved " .. player_name
			.. " to channel " .. channel_name)
	end
	return true
end

minetest.register_chatcommand("force2channel", {
	params = "<Channel Name>, <Player Name>",
	description = "Force player named <Player Name> to channel named <Channel Name>. Requires ban privilege.",
	privs = { ban = true },
	func = beerchat.force_player_to_channel
})
