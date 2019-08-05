
--
-- Mod settings -- Change these to your liking

beerchat = {
	-- The main channel is the one you send messages to when no channel is specified
	main_channel_name = "main",

	-- The default color of channels when no color is specified
	default_channel_color = "#ffffff",

	-- Global flag to enable/ disable sounds
	enable_sounds = true,

	-- General sound when managing channels like /cc, /dc etc
	channel_management_sound = "beerchat_chirp",

	-- Sound when a message is sent to a channel
	channel_message_sound = "beerchat_chime",

	main_channel_message_string = "|#${channel_name}| <${from_player}> ${message}",

	channels = {},
	playersChannels = {},
	currentPlayerChannel = {}
}

local MP = minetest.get_modpath("beerchat")
dofile(MP.."/storage.lua")
dofile(MP.."/session.lua")
dofile(MP.."/message.lua")
dofile(MP.."/pm.lua")
dofile(MP.."/hash.lua")
dofile(MP.."/me.lua")
dofile(MP.."/whisper.lua")
dofile(MP.."/chatcommands.lua")



print("[OK] beerchat")
