-- default relay commands

------------------
-- TODO: cleanup
------------------

local DAY = 24 * 3600
local HOUR = 3600

local function human_readable_seconds(n)
	-- sanitize (not needed in this usgage case
	--if not is_number(n) then return "n/a" end

	local s = ""
	n = math.floor(n)
	local days = math.floor(n / DAY)
	n = n - days * DAY
	local hours = math.floor(n / HOUR)
	n = n - hours * HOUR
	local minutes = math.floor(n / 60)
	n = n - minutes * 60

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

local function players_list()
	local players = {}
	for _, player in ipairs(minetest.get_connected_players()) do
		table.insert(players, player:get_player_name())
	end
	if 0 == #players then
		return 'No players connected.'
	end

	return 'Players: ' .. table.concat(players, ', ')
end

local function command_status()
	local aOut = {}
	table.insert(aOut, 'Uptime:')
	table.insert(aOut, human_readable_seconds(minetest.get_server_uptime()))
    -- TODO:
	--* `minetest.get_server_max_lag()`: returns the current maximum lag
	-- of the server in seconds or nil if server is not fully loaded yet
	table.insert(aOut, 'max lag:')
	table.insert(aOut, math.floor(1000 * minetest.get_server_max_lag()) * .001)
	table.insert(aOut, 's')
	table.insert(aOut, players_list())
	return table.concat(aOut, ' ')
end

-- !status
beerchat.register_relaycommand("status", function()
	return command_status()
end)

-- !players
beerchat.register_relaycommand("players", function()
	return players_list()
end)
