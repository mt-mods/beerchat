
local whisper_default_range = 32		-- Default whisper range when whispering without specifying a radius
local whisper_max_range = 200			-- Maximum whisper range that can be specified when whispering

-- $ chat a.k.a. dollar chat code, to whisper messages in chat to nearby players only using $,
-- optionally supplying a radius e.g. $32 Hello
beerchat.register_on_chat_message(function(name, message)

	-- Handle only messages beginning with $
	if message:sub(1,1) ~= "$" then
		-- Message not handled, continue processing message
		return false
	end

	local sradius, msg = string.match(message, "^$(.-) (.*)")
	local radius = tonumber(sradius) or whisper_default_range
	if radius > whisper_max_range then
		minetest.chat_send_player(name, "You cannot whisper outside of a radius of " .. whisper_max_range .. " nodes")
	elseif msg == "" then
		minetest.chat_send_player(name, "Please enter the message you would like to whisper to nearby players")
	elseif not beerchat.whisper(name, msg, radius) then
		minetest.chat_send_player(name, "no one heard you whispering!")
	end

	-- Message handled, stop processing message
	return true

end)
