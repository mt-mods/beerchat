
--luacheck: globals minetest.registered_chatcommands.tell

minetest.register_on_mods_loaded(function()

	-- Override /tell chat command to execute callbacks.
	-- Command is added by mesecons command block.
	if minetest.registered_chatcommands.tell then
		local tell = minetest.registered_chatcommands.tell.func
		minetest.registered_chatcommands.tell.func = function(name, param)
			local target, message = param:match("^([^%s]+)%s+(.*)$")
			local cb_result, cb_message = beerchat.execute_callbacks('before_send_pm', name, message, target)
			if cb_result then
				return tell(name, param)
			end
			if cb_message then
				minetest.chat_send_player(name, cb_message)
			end
		end
	end

end)
