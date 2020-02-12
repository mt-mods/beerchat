
beerchat.cb = {} -- all custom callbacks

beerchat.cb.before_send 		= {} -- executed before sending message
beerchat.cb.before_send_pm 		= {} -- executed before sending private message
beerchat.cb.before_send_me		= {} -- executed before /me message is sent
beerchat.cb.before_whisper		= {} -- executed before whisper message is sent
beerchat.cb.before_join 		= {} -- executed before channel is joined
beerchat.cb.before_leave 		= {} -- executed before channel is leaved
beerchat.cb.before_invite 		= {} -- excuted before channel invitation takes place
beerchat.cb.before_check_muted 	= {} -- executed before has_player_muted_player checks
beerchat.cb.on_forced_join 		= {} -- executed right after player is forced to channel

beerchat.register_callback = function(trigger, fn)
	if type(fn) ~= 'function' then
		print('Error: Invalid fn argument for beerchat.register_callback, must be function')
		return
	end
	if type(trigger) ~= 'string' then
		print('Error: Invalid trigger argument for beerchat.register_callback, must be string')
		return
	end

	local cb = beerchat.cb
	local callback_key = trigger

	if not cb[callback_key] then
		print('Error: Invalid callback trigger event, possible triggers:')
		for k,_ in pairs(cb) do
			print(' ->   ' .. k)
		end
		return
	end

	table.insert(cb[callback_key], fn)
end

beerchat.execute_callbacks = function(trigger, ...)
	local cb_list = beerchat.cb[trigger]
	if not cb_list then
		print('Error: Invalid trigger argument for beerchat.execute_callbacks')
		-- This is internal error / dev error, stop processing current event
		return false
	end
	for _,fn in ipairs(cb_list) do
		local result = fn(unpack(arg))
		if result ~= nil then
			return result
		end
	end
	return true
end

-- called on every channel message
-- params: channel, playername, message
beerchat.on_channel_message = function()
end
