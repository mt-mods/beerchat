local whisperers = {}

-- Returns true when someone heard whisper and false if nobody else can hear whisper (cancelled, too far, no position)
local function whisper(pos, radius, name, msg, channel, fmtstr, color)
	if not beerchat.execute_callbacks('before_whisper', name, msg, channel, radius, pos) then
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
			if beerchat.is_player_subscribed_to_channel(target, channel) then
				-- check if muted
				if not beerchat.has_player_muted_player(target, name) then
					-- mark as sent if anyone else is hearing it
					if name ~= target then
						successful = true
					end
					-- deliver message
					beerchat.send_message(
						target,
						beerchat.format_message(fmtstr, {
							channel_name = channel,
							from_player = name,
							to_player = target,
							message = msg,
							color = color
						}),
						channel
					)
				end
			end
		end
	end
	return successful
end

local whisper_default_range = tonumber(minetest.settings:get("beerchat.whisper.range")) or 32
local whisper_max_range = tonumber(minetest.settings:get("beerchat.whisper.max_range")) or 200
local whisper_color = minetest.settings:get("beerchat.whisper.color") or "#aaaaaa"
local whisper_string = minetest.settings:get("beerchat.whisper.format") or
	"|#${channel_name}| <${from_player}> whispers: ${message}"
local whisper_channel = beerchat.main_channel_name

-- Send message to players near position, public API function for backward compatibility.
-- $ chat a.k.a. dollar chat code, to whisper messages in chat to nearby players only using $,
-- optionally supplying a radius e.g. $32 Hello
beerchat.whisper = function(name, message)
	-- Handle only messages beginning with $
	local whisper_command = message:sub(1,1) == "$"
	if whisperers[name] then
		if whisper_command then
			whisperers[name] = nil
			minetest.chat_send_player(name, "Whisper mode canceled, messages will be sent to channel")
			return true
		end
		local player = minetest.get_player_by_name(name)
		if player then
			local radius = whisperers[name]
			if not whisper(player:get_pos(), radius, name, message, whisper_channel, whisper_string, whisper_color) then
				minetest.chat_send_player(name, "no one heard you whispering!")
			end
		end
		return true
	elseif whisper_command then
		local sradius, msg = string.match(message, "^$(.-) (.*)")
		local radius = tonumber(sradius) or whisper_default_range
		local player = minetest.get_player_by_name(name)
		if radius > whisper_max_range then
			minetest.chat_send_player(name, "You cannot whisper outside of a radius of "..whisper_max_range.." nodes")
		elseif msg == "" then
			whisperers[name] = radius
			minetest.chat_send_player(name, "Whisper mode activated, to cancel write $ again without message")
		elseif player then
			if not whisper(player:get_pos(), radius, name, msg, whisper_channel, whisper_string, whisper_color) then
				minetest.chat_send_player(name, "no one heard you whispering!")
			end
		end
		-- Message handled, stop processing message
		return true
	end
end

beerchat.register_on_chat_message(beerchat.whisper)

minetest.register_chatcommand("whis", {
	params = "<message>",
	description = "Whisper command for those who can't use $",
	func = function(name, param) beerchat.whisper(name, "$ " .. param) end
})
