
local whisper_default_range = 32		-- Default whisper range when whispering without specifying a radius
local whisper_max_range = 200			-- Maximum whisper range that can be specified when whispering
local whisper_color = "#aaaaaa"			-- Whisper color override

local whisper_string = "|#${channel_name}| <${from_player}> whispers: ${message}"

-- $ chat a.k.a. dollar chat code, to whisper messages in chat to nearby players only using $, optionally supplying a radius e.g. $32 Hello
minetest.register_on_chat_message(function(name, message)
	local dollar, sradius, msg = string.match(message, "^($)(.-) (.*)")
	if dollar == "$" then
		local radius = tonumber(sradius)
		if not radius then
			radius = whisper_default_range
		end

		if radius > whisper_max_range then
			minetest.chat_send_player(name, "You cannot whisper outside of a radius of "..whisper_max_range.." blocks")
		elseif msg == "" then
			minetest.chat_send_player(name, "Please enter the message you would like to whisper to nearby players")
		else
			local pl = minetest.get_player_by_name(name)
			local all_objects = minetest.get_objects_inside_radius({x=pl:getpos().x, y=pl:getpos().y, z=pl:getpos().z}, radius)

			for _,player in ipairs(all_objects) do
				if player:is_player() then
					local target = player:get_player_name()
					-- Checking if the target is in this channel
					if beerchat.playersChannels[target] and beerchat.playersChannels[target][beerchat.main_channel_name] then
						if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
							minetest.chat_send_player(target, format_message(whisper_string, {
								channel_name = beerchat.main_channel_name, from_player = name, message = msg, color = whisper_color
							}))
						end
					end
				end
			end
			return true
		end
	end
end)