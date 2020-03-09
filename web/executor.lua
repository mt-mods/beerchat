
beerchat.executor = function(str, playername)
	minetest.log("action", "[beerchat] executing: '" .. str .. "' as " .. playername)

	local found, _, commandname, params = str:find("^([^%s]+)%s(.+)$")
	if not found then
		commandname = str
	end

	local command = minetest.chatcommands[commandname]
	if not command then
		return false, "Not a valid command: " .. commandname
	end

  if command.privs and not minetest.check_player_privs(playername, command.privs) then
		return false, "Not enough privileges!"
	end

	local result, message

	local status, err = pcall(function()
		result, message = command.func(playername, (params or ""))
	end)

	if not status then
		message = dump(err)
		result = false
	end

	return result, message
end
