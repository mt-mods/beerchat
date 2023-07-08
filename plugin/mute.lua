
local is_muted = function(name, target)
	if target then
		local player = minetest.get_player_by_name(target)
		if player then
			local meta = player:get_meta()
			return meta:get("beerchat:muted:" .. name) == "true"
		end
		return true
	end
	return false
end

-- Events

beerchat.register_callback("before_send_pm", function(name, _, target)
	if is_muted(name, target) then
		return false
	end
end)

beerchat.register_callback("before_check_muted", function(name, target)
	if is_muted(name, target) then
		return false
	end
end)

beerchat.register_callback("on_send_on_channel", function(name, _, target)
	if is_muted(name, target) then
		return false
	end
end)

-- Chat commands

local mute_player = {
	params = "<Player Name>",
	description = "Mute a player. After muting a player, you will no longer see chat "
		.. "messages of this user, regardless of what channel his user sends messages to.",
	func = function(name, param)

		if not beerchat.execute_callbacks("before_mute", name, param) then
			return false
		end

		if not param or param == "" then
			return false, "ERROR: Invalid number of arguments. Please supply the name "
				.. "of the user to mute."
		end

		if beerchat.has_player_muted_player(name, param) then
			minetest.chat_send_player(name, "Player " .. param .. " is already muted.")
		else
			minetest.get_player_by_name(name):get_meta():set_string(
				"beerchat:muted:" .. param, "true")
			minetest.chat_send_player(name, "Muted player " .. param .. ".")
		end
		return true
	end
}

local unmute_player = {
	params = "<Player Name>",
	description = "Unmute a player. After unmuting a player, you will again see chat "
		.. "messages of this user",
	func = function(name, param)
		if not param or param == "" then
			return false, "ERROR: Invalid number of arguments. Please supply the "
				.. "name of the user to mute."
		end

		if beerchat.has_player_muted_player(name, param) then
			minetest.get_player_by_name(name):get_meta():set_string(
				"beerchat:muted:" .. param, "")
			minetest.chat_send_player(name, "Unmuted player " .. param .. ".")
		else
			minetest.chat_send_player(name, "Player " .. param .. " was not muted.")
		end
		return true
	end
}

local list_muted = {
	params = "",
	description = "Show list of muted players.",
	func = function(name)

		local player = minetest.get_player_by_name(name)
		local tMeta = player:get_meta():to_table()

		if nil == tMeta or nil == tMeta.fields then return false end

		local sOut = ""
		for sKey, _ in pairs(tMeta.fields) do
			if "beerchat:muted:" == sKey:sub(1, 15) then
				sOut = sOut .. sKey:sub(16, -1) .. ", "
			end
		end

		if 0 == #sOut then
			sOut = "You have not muted any players."
		else
			-- remove trailing comma and space
			sOut = sOut:sub(1, -3)
		end
		minetest.chat_send_player(name, sOut)
		return true
	end
}

minetest.register_chatcommand("mute", mute_player)
minetest.register_chatcommand("ignore", mute_player)
minetest.register_chatcommand("unmute", unmute_player)
minetest.register_chatcommand("unignore", unmute_player)
minetest.register_chatcommand("list_muted", list_muted)
