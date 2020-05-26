
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
		minetest.chat_send_player(name, "You cannot whisper outside of a radius of "
			.. whisper_max_range .. " nodes")
	elseif msg == "" then
		minetest.chat_send_player(name, "Please enter the message you would like to "
			.. "whisper to nearby players")
	else
		local cb_result, cb_message = beerchat.execute_callbacks('before_whisper',
			name, msg, beerchat.main_channel_name, radius)
		if not cb_result then
			if cb_message then return false, cb_message else return false end
		end

		-- true if someone heard the player
		local successful = false
		local player = minetest.get_player_by_name(name)
		for _, other_player in ipairs(minetest.get_connected_players()) do
			-- calculate distance
			local opos = other_player:get_pos()
			local ppos = player:get_pos()
			local distance = vector.distance(opos, ppos)

			if distance < radius then
				-- player in range
				local target = other_player:get_player_name()

				-- Checking if the target is in this channel
				if beerchat.is_player_subscribed_to_channel(target, beerchat.main_channel_name) then

					-- check if muted
					if not beerchat.has_player_muted_player(target, name) then
						-- mark as sent if anyone else is hearing it
						if name ~= other_player:get_player_name() then
							successful = true
						end

						-- deliver message
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

		if successful then
			return true
		else
			return false, "no one heard you whispering!"
		end
	end
end

minetest.register_on_chat_message(beerchat.whisper)
