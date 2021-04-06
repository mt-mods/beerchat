
-- Load all integrated beerchat extensions here

local MP = minetest.get_modpath("beerchat")
local function load_plugin(name, enable_default)
	if minetest.settings:get_bool("beerchat.enable_"..name, enable_default) then
		print("Loading beerchat plugin: " .. name)
		dofile(MP.."/plugin/"..name..".lua")
	else
		print("Beerchat plugin disabled: " .. name)
	end
end

-- Allows sending special formatted "/me message here" messages to channel
load_plugin("me", true)

-- Allows switching channels with "#channelname" and sending to channel with "#channelname message here"
load_plugin("hash", true)

-- Allows "$ message here" to send message to nearby players
load_plugin("whisper", true)

-- Allows "@player message here" to send private messages to players
load_plugin("pm", true)

-- Adds "/chat_jail playername" and "/chat_unjail playername" commands
load_plugin("jail", false)

-- Removes control characters from incoming messages
load_plugin("cleaner", false)

-- Overrides for message handlers provided by other mods
load_plugin("override", false)

-- Allows colorizing messages on specified channels
load_plugin("colorize", true)
