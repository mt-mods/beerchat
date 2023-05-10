--luacheck: no_unused_args

beerchat.alias = {
	priv = minetest.settings:get("beerchat.alias.priv") or "ban"
}

local channels = minetest.deserialize(beerchat.mod_storage:get("alias.channels")) or {}

local function write_storage()
	local data = minetest.serialize(channels)
	beerchat.mod_storage:set_string("alias.channels", data)
end

local function switch_player_channel(name, alias, resolved)
	-- Aliases can allow joining protected channel without authorization.
	if beerchat.get_player_channel(name) == alias then
		-- Add and move player to resolved channel
		beerchat.set_player_channel(name, resolved)
	else
		-- Add player to resolved channel but keep active channel
		beerchat.add_player_channel(name, resolved)
	end
end

local function resolve_alias(alias)
	if channels[alias] then
		if beerchat.channels[channels[alias]] then
			return channels[alias]
		end
		-- Cleanup invalid alias, target channel disappeared
		channels[alias] = nil
	end
end

local function add_alias(alias, target)
	if alias ~= target and not channels[alias] then
		-- Always use canonical name, resolve first to make direct links and skip chaining
		local resolved = resolve_alias(target) or target
		if resolved ~= alias then
			-- Add alias if resolution seems sane
			channels[alias] = resolved
			write_storage()
			for _,player in ipairs(minetest.get_connected_players()) do
				local name = player:get_player_name()
				if beerchat.playersChannels[name][alias] then
					switch_player_channel(name, alias, target)
				end
			end
			return true
		end
	end
end

local function remove_alias(alias)
	channels[alias] = nil
end

beerchat.register_callback("before_send_on_channel", function(name, msg)
	local resolved = resolve_alias(msg.channel)
	if resolved then
		msg.channel = resolved
	end
end, "high")

beerchat.register_callback('before_switch_chan', function(name, switch)
	local resolved = resolve_alias(switch.to)
	if resolved then
		if resolved == switch.from then
			-- cannot switch back to origin
			return false, "Channel #" .. switch.to .. " is alias for #" .. switch.from .. " and you are already there."
		end
		switch.to = resolved
	end
end, "high")

--[[ HANDLERS FOR THESE EVENTS ARE WANTED BUT NOT YET FLEXIBLE ENOUGH FOR CHANNEL ALIASES:
beerchat.register_callback('before_invite', function(name, recipient, channel) end, true)
beerchat.register_callback('before_join', function(name, channel) end, true)
beerchat.register_callback('before_leave', function(name, channel) end, true)
beerchat.register_callback('before_send_me', function(name, message, channel) end, true)
beerchat.register_callback('on_forced_join', function(name, target, channel, from_channel) end, true)
--]]

minetest.register_chatcommand("channel-alias", {
	params = "<Alias name> [<Channel Name>]",
	description = "Link <Alias name> channel to <Channel Name> channel. Both channels must exist."
		.. "\nResolves alias to channel name if only first argument is given."
		.. "\nRequires `" .. beerchat.alias.priv .. "` privileges and channel ownership for alias management.",
	func = function(name, param)
		local match = param:gmatch("#?([^%s,]+)")
		local alias, channel = match(), match()

		-- Check arguments, either not enough or too many arguments
		if not alias or match() then
			return false, "ERROR: Invalid number of arguments. Please supply the channel names."
		end

		-- Resolve alias end return results if channel argument is not supplied
		if not channel then
			local resolved = resolve_alias(alias)
			if resolved then
				return true, "Alias #" .. alias .. " resolved to #" .. resolved .. "."
			end
			local found = {}
			for calias, chan in pairs(channels) do
				if alias == chan then
					table.insert(found, "#" .. calias)
				end
			end
			if #found > 0 then
				return true, "Resolving #" .. alias .. " failed. " ..
					"Instead it is regular channel with following aliases:\n" .. table.concat(found, ", ")
			end
			return true, "Could not resolve #" .. alias .. " to channel, it does not seem to be alias."
		end

		if alias == beerchat.main_channel_name then
			return false, "ERROR: Cannot convert main channel to alias!"
		end

		if not beerchat.channels[alias] then
			return false, "ERROR: Channel #" .. alias .. " does not exist."
		end

		if not beerchat.channels[channel] then
			return false, "ERROR: Channel #" .. channel .. " does not exist."
		end

		if not minetest.check_player_privs(name, beerchat.admin_priv) then
			if not minetest.check_player_privs(name, beerchat.alias.priv) then
				return false, "ERROR: Privilege `" .. beerchat.alias.priv .. "` is required to manage channel aliases"
			end
			if name ~= beerchat.channels[alias].owner then
				return false, "ERROR: You are not the owner of alias #" .. alias
			end
			if name ~= beerchat.channels[channel].owner then
				return false, "ERROR: You are not the owner of channel #" .. channel
			end
		end

		add_alias(alias, channel)
		return true, "Alias #" .. alias .. " created. You can now use both names to access #" .. channel .. "."
	end
})

minetest.register_chatcommand("channel-unalias", {
	params = "<Alias name>",
	description = "Unlink <Alias name> channel and make it regular channel."
		.. "\nRequires `" .. beerchat.alias.priv .. "` privileges and alias ownership for alias management.",
	func = function(name, param)
		local alias = param:match("^#?(%S+)$")
		if not alias then
			return false, "ERROR: Invalid number of arguments. Please supply the alias name."
		end

		local resolved = resolve_alias(alias)
		if not resolved then
			return true, "Could not resolve #" .. alias .. " to channel, it does not seem to be alias."
		end

		if not minetest.check_player_privs(name, beerchat.admin_priv) then
			if not minetest.check_player_privs(name, beerchat.alias.priv) then
				return false, "ERROR: Privilege `" .. beerchat.alias.priv .. "` is required to manage channel aliases"
			end
			if beerchat.channels[alias] and name ~= beerchat.channels[alias].owner then
				return false, "ERROR: You are not the owner of alias #" .. alias
			end
		end

		remove_alias(alias)
		return true, "Alias #" .. alias .. " converted to regular channel. Delete channel if not needed anymore."
	end
})
