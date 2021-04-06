
local colorize_channels = minetest.settings:get("beerchat.colorize_channels")

if colorize_channels then

	local channels = string.gmatch(colorize_channels, "[^%s,]+")
	local allowed_channels = {}
	for channel in channels do
		allowed_channels[channel] = true
	end

	if next(allowed_channels) then
		beerchat.register_callback('on_send_on_channel', function(msg_data)
			if msg_data.channel and allowed_channels[msg_data.channel] then
				msg_data.message = msg_data.message:gsub('%((%#%x%x%x)%)', string.char(0x1B) .. '(c@%1)')
			end
		end)
	end

end
