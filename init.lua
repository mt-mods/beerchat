
--
-- Mod settings -- Change these to your liking


local http = QoS and QoS(minetest.request_http_api(), 1) or minetest.request_http_api()

beerchat = {
	-- The main channel is the one you send messages to when no channel is specified
	main_channel_name = minetest.settings:get("beerchat.main_channel_name") or "main",

	-- The default color of channels when no color is specified
	default_channel_color = "#ffffff",

	-- Global flag to enable/ disable sounds
	enable_sounds = true,

	-- how loud the sounds should be by default (0.0 = low, 1.0 = max)
	sounds_default_gain = 0.3,

	-- General sound when managing channels like /cc, /dc etc
	channel_management_sound = "beerchat_chirp",

	-- Sound when a message is sent to a channel
	channel_message_sound = "beerchat_chime",

	main_channel_message_string = "|#${channel_name}| <${from_player}> ${message}",

	moderator_channel_name = minetest.settings:get("beerchat.moderator_channel_name"),

	mod_storage = minetest.get_mod_storage(),

	channels = {},
	playersChannels = {},
	currentPlayerChannel = {},

	-- web settings
	url = minetest.settings:get("beerchat.matterbridge_url") or "http://127.0.0.1:4242",

	-- mapped remote users (irc, discord)
	-- data: local user => remote user
	remote_username_map = {}
}

local MP = minetest.get_modpath("beerchat")
dofile(MP.."/router.lua")

dofile(MP.."/common.lua")
dofile(MP.."/format_message.lua")
dofile(MP.."/hooks.lua")
dofile(MP.."/storage.lua")
dofile(MP.."/session.lua")
dofile(MP.."/message.lua")
dofile(MP.."/chatcommands.lua")

if http then
	-- load web stuff
	print("[beerchat] connecting to proxy-endpoint at: " .. beerchat.url)

	dofile(MP.."/web/executor.lua")
	dofile(MP.."/web/audit.lua")
	dofile(MP.."/web/login.lua")
	dofile(MP.."/web/logout.lua")
	dofile(MP.."/web/common.lua")
	loadfile(MP.."/web/tx.lua")(http)
	loadfile(MP.."/web/rx.lua")(http)
end

-- Load beerchat extensions
dofile(MP.."/plugin/init.lua")
