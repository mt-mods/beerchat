
--
-- Mod settings -- Change these to your liking


local http = minetest.request_http_api()

beerchat = {
	-- The main channel is the one you send messages to when no channel is specified
	main_channel_name = "main",

	jail_channel_name = "wail",

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

	mod_storage = minetest.get_mod_storage(),

	channels = {},
	playersChannels = {},
	currentPlayerChannel = {},

	-- web settings
	url = minetest.settings:get("beerchat.url") or "http://127.0.0.1:8080",
	http = http -- will be removed after init

}

local MP = minetest.get_modpath("beerchat")
dofile(MP.."/common.lua")
dofile(MP.."/format_message.lua")
dofile(MP.."/hooks.lua")
dofile(MP.."/storage.lua")
dofile(MP.."/jail.lua")
dofile(MP.."/session.lua")
dofile(MP.."/pm.lua")
dofile(MP.."/hash.lua")
dofile(MP.."/me.lua")
dofile(MP.."/whisper.lua")
dofile(MP.."/message.lua")
dofile(MP.."/chatcommands.lua")

if beerchat.http then
	-- load web stuff
	print("beerchat connects to proxy-endpoint at: " .. beerchat.url)

	dofile(MP.."/web/executor.lua")
	dofile(MP.."/web/tx.lua")
	dofile(MP.."/web/rx.lua")
end

-- remove http ref
beerchat.http = nil



print("[OK] beerchat")
