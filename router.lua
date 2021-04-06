
-- Entry point for all messages handled by beerchat, ensures that all on_receive hooks accept
-- message before allowing any plugin or default handler to actually handle message.

local on_chat_message_handlers = {}

function beerchat.register_on_chat_message(func)
	table.insert(on_chat_message_handlers, func)
end

-- All messages are handled either by sending to channel or through special plugin function.
minetest.register_on_chat_message(function(name, message)

	-- Execute or_receive callbacks allowing modifications to sender and message
	local msg_data = {name=name,message=message}
	if beerchat.execute_callbacks('on_receive', msg_data) then
		message = msg_data.message
		name = msg_data.name
	else
		print("Beerchat message discarded by on_receive hook, contents went to /dev/null")
		return true
	end

	-- Execute mesasge handlers
	for _, handler in ipairs(on_chat_message_handlers) do
		if handler(name, message) then
			-- Last executed handler marked message as handled, return
			return true
		end
	end

	-- This should never happen, beerchat must handle all messages.
	-- FIXME: Call default handler directly here instead of using hacky on_mods_loaded hook in message.lua
	error("Beerchat was unable to handle message: " .. dump(name) .. ", " .. dump(message))

end)
