
local whisper_default_range = 32		-- Default whisper range when whispering without specifying a radius
local whisper_max_range = 200			-- Maximum whisper range that can be specified when whispering
local whisper_color = "#aaaaaa"			-- Whisper color override

local whisper_string = "|#${channel_name}| <${from_player}> whispers: ${message}"

-- $ chat a.k.a. dollar chat code, to whisper messages in chat to nearby players only using $,
-- optionally supplying a radius e.g. $32 Hello
beerchat.whisper = function(name, message)
	local dollar, sradius, msg = string.match(message, "^($)(.-) (.*)")
	if dollar ~= "$" then
		return false
	end
	local radius = tonumber(sradius)
	if not radius then
		radius = whisper_default_range
	end

	if radius > whisper_max_range then
		minetest.chat_send_player(name, "You cannot whisper outside of a radius of "..whisper_max_range.." nodes")
	elseif msg == "" then
		minetest.chat_send_player(name, "Please enter the message you would like to whisper to nearby players")
	else
		local cb_result, cb_message = beerchat.execute_callbacks('before_send_whisper', name, msg, beerchat.main_channel_name, radius)
		if not cb_result then
			return cb_message and (false, cb_message) or false
		end

		local pl = minetest.get_player_by_name(name)
		local pl_pos = pl:getpos()
		local all_objects = minetest.get_objects_inside_radius({x=pl_pos.x, y=pl_pos.y, z=pl_pos.z}, radius)

		for _,player in ipairs(all_objects) do
			if player:is_player() then
				local target = player:get_player_name()
				-- Checking if the target is in this channel
				if beerchat.is_player_subscribed_to_channel(target, beerchat.main_channel_name) then
					if not beerchat.has_player_muted_player(target, name) then
						beerchat.send_message(
							target,
							beerchat.format_message(whisper_string, {
								channel_name = beerchat.main_channel_name,
								from_player = name,
								to_player = target,
								message = msg,
								color = whisper_color
							}),
							beerchat.main_channel_name
						)
					end
				end
			end
		end
		return true
	end
end

minetest.register_on_chat_message(beerchat.whisper)

