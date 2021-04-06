
beerchat.has_player_muted_player = function(name, other_name)
	local cb_result = beerchat.execute_callbacks('before_check_muted', name, other_name)
	if cb_result ~= nil then
		return cb_result
	end

	local player = minetest.get_player_by_name(name)
	-- check jic method is used incorrectly
	if not player then
		return true
	end

	local key = "beerchat:muted:" .. other_name
	local meta = player:get_meta()
	return "true" == meta:get_string(key)
end -- has_player_muted_player

beerchat.is_player_subscribed_to_channel = function(name, channel)
	return (nil ~= beerchat.playersChannels[name])
		and (nil ~= beerchat.playersChannels[name][channel])
end -- is_player_subscribed_to_channel

beerchat.send_message = function(name, message, channel)
	if not beerchat.execute_callbacks('before_send', name, message, channel) then
		return
	end

	minetest.chat_send_player(name, message)
-- TODO: read player settings for channel sounds
	if beerchat.enable_sounds and channel ~= beerchat.main_channel_name then
		minetest.sound_play(beerchat.channel_message_sound, { to_player = name, gain = beerchat.sounds_default_gain } )
	end
end -- send_message

-- Send message to players near position.
-- radius and pos are optional to ensure backward compatibility of public API.
-- Returns true when someone heard whisper and false if nobody else can hear whisper (cancelled, too far, no position)
local whisper_color = "#aaaaaa"
local whisper_string = "|#${channel_name}| <${from_player}> whispers: ${message}"
beerchat.whisper = function(name, msg, radius, pos)
	radius = radius or 32
	-- if position not given try to use player position, this is done here to ensure backward compatibility
	if not pos then
		local player = minetest.get_player_by_name(name)
		if not player then
			return false
		end
		pos = player:get_pos()
	end

	if not beerchat.execute_callbacks('before_whisper', name, msg, beerchat.main_channel_name, radius, pos) then
		-- Whispering was cancelled by one of external callbacks
		return false
	end

	-- true if someone heard the player
	local successful = false
	for _, other_player in ipairs(minetest.get_connected_players()) do
		-- calculate distance
		local opos = other_player:get_pos()
		local distance = vector.distance(opos, pos)
		if distance < radius then
			-- player in range
			local target = other_player:get_player_name()
			-- Checking if the target is in this channel
			if beerchat.is_player_subscribed_to_channel(target, beerchat.main_channel_name) then
				-- check if muted
				if not beerchat.has_player_muted_player(target, name) then
					-- mark as sent if anyone else is hearing it
					if name ~= target then
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
	return successful
end
