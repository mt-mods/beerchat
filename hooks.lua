
beerchat.cb = {} -- all custom callbacks

beerchat.cb.before_send 		= {} -- executed before sending message
beerchat.cb.before_send_pm 		= {} -- executed before sending private message
beerchat.cb.before_send_me		= {} -- executed before /me message is sent
beerchat.cb.before_whisper		= {} -- executed before whisper message is sent
beerchat.cb.before_join 		= {} -- executed before channel is joined
beerchat.cb.before_leave 		= {} -- executed before channel is leaved
beerchat.cb.before_switch_chan 	= {} -- executed before channel is changed
beerchat.cb.before_invite 		= {} -- excuted before channel invitation takes place
beerchat.cb.before_mute 		= {} -- executed before player is muted
beerchat.cb.before_check_muted 	= {} -- executed before has_player_muted_player checks
beerchat.cb.on_forced_join 		= {} -- executed right after player is forced to channel

-- Callbacks that can edit message contents
beerchat.cb.on_receive 			= {} -- executed when new message is received
beerchat.cb.on_http_receive 		= {} -- executed when new message is received through http polling
beerchat.cb.on_send_on_channel		= {} -- executed before sending message to channel

beerchat.register_callback = function(trigger, fn)
	if type(fn) ~= 'function' then
		print('Error: Invalid fn argument for beerchat.register_callback, must be function. Got ' .. type(fn))
		return
	end
	if type(trigger) ~= 'string' then
		print('Error: Invalid trigger argument for beerchat.register_callback, must be string. Got ' .. type(trigger))
		return
	end

	if not beerchat.cb[trigger] then
		print(string.format('Error: Invalid callback trigger event %s, possible triggers:', trigger))
		for k,_ in pairs(beerchat.cb) do
			print(' ->   ' .. k)
		end
		return
	end

	table.insert(beerchat.cb[trigger], fn)
end

beerchat.execute_callbacks = function(trigger, ...)
	local cb_list = beerchat.cb[trigger]
	local arg = {...}
	for _,fn in ipairs(cb_list) do
		local result, msg = fn(unpack(arg))
		if result ~= nil then
			if msg and type(arg[1]) == "string" then
				minetest.chat_send_player(arg[1], msg)
			end
			return result
		end
	end
	if trigger == 'before_check_muted' then
		-- requires special handling, might need to create another callback registration for special methods
		return nil
	end
	return true
end

-- TODO: harmonize callbacks

-- called on every channel message
-- params: channel, playername, message
beerchat.on_channel_message = function()
end

-- called on every /me message
-- params: channel, playername, message
beerchat.on_me_message = function()
end
