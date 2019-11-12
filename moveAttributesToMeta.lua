-- transfer user information from depricated attributes to player metaRef

-- called when player joins
beerchat.moveAttributesToMeta = function(player)
	local meta = player:get_meta()
	local str = player:get_attribute("beerchat:channels")
	if str and str ~= "" then
		meta:set_string("beerchat:channels", str)
		player:set_attribute("beerchat:channels", nil)
	end

	local current_channel = player:get_attribute("beerchat:current_channel")
	if current_channel and current_channel ~= "" then
		meta:set_string("beerchat:current_channel", current_channel)
		player:set_attribute("beerchat:current_channel", nil)
	end
	
end -- moveAttributesToMeta
