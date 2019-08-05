local mod_storage = minetest.get_mod_storage()

local main_channel_owner = "Beerholder"		-- The owner of the main channel, usually ADMIN
local main_channel_color = "#ffffff"		-- The color in hex of the main channel


if mod_storage:get_string("channels") == "" then
	minetest.log("action", "[beerchat] One off initializing mod storage")
	beerchat.channels[beerchat.main_channel_name] = { owner = main_channel_owner, color = main_channel_color }
	mod_storage:set_string("channels", minetest.write_json(beerchat.channels))
end

beerchat.channels = minetest.parse_json(mod_storage:get_string("channels"))
