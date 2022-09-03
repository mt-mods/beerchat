-- default relay commands

------------------
-- TODO: cleanup, test
------------------

-- helper function for !status command
local DAY = 24 * 3600
local HOUR = 3600
local function human_readable_seconds(n)
	-- sanitize (not needed in this usgage case
	--if not is_number(n) then return "n/a" end

	local s = ""
	-- drop fractions of seconds
	n = math.floor(n)
	-- extract days, hours and minutes
	local days = math.floor(n / DAY)
	n = n - days * DAY
	local hours = math.floor(n / HOUR)
	n = n - hours * HOUR
	local minutes = math.floor(n / 60)
	n = n - minutes * 60

	-- add non-zero elements to output string s
	if days > 0 then
		s = s .. ' ' .. tostring(days) .. ' day'
		if days ~= 1 then s = s .. 's' end
	end
	if hours > 0 then
		s = s .. ' ' .. tostring(hours) .. ' hour'
		if hours ~= 1 then s = s .. 's' end
	end
	if minutes > 0 then
		s = s .. ' ' .. tostring(minutes) .. ' minute'
		if minutes ~= 1 then s = s .. 's' end
	end
	if n > 0 then
		s = s .. ' ' .. tostring(n) .. ' second'
		if n ~= 1 then s = s .. 's' end
	end

	return s
end

-- helper function for !players and !status commands
local function players_list()
	-- loop all online names into a list
	local player_names = {}
	for _, player in ipairs(minetest.get_connected_players()) do
		table.insert(player_names, player:get_player_name())
	end

	-- abort if there are no players connected
	if 0 == #player_names then
		return 'No players connected.'
	end

	-- collapse list into coma separated string
	return 'Players: ' .. table.concat(player_names, ', ')
end

-- function for !status command
local function command_status()
	local out = {}

	-- uptime in human readable format
	table.insert(out, 'Uptime:')
	table.insert(out, human_readable_seconds(minetest.get_server_uptime()))

	-- max lag seconds
	local lag_max = minetest.get_server_max_lag()
	if lag_max then
		table.insert(out, 'max lag:')
		table.insert(out, math.floor(100 * lag_max) * .01)
		table.insert(out, 's')
	end

	-- list of player names
	table.insert(out, players_list())

	-- collapse list into a string and return
	return table.concat(out, ' ')
end

-- !status
beerchat.register_relaycommand("status", function()
	return command_status()
end)

-- !players
beerchat.register_relaycommand("players", function()
	return players_list()
end)
