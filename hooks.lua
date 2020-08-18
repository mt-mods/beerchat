
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

beerchat.register_callback = function(trigger, fn)
	if type(fn) ~= 'function' then
		print('Error: Invalid fn argument for beerchat.register_callback, must be function. Got ' .. type(fn))
		return
	end
	if type(trigger) ~= 'string' then
		print('Error: Invalid trigger argument for beerchat.register_callback, must be string. Got ' .. type(trigger))
		return
	end

	local cb = beerchat.cb

	if not cb[trigger] then
		print(string.format('Error: Invalid callback trigger event %s, possible triggers:', trigger))
		for k,_ in pairs(cb) do
			print(' ->   ' .. k)
		end
		return
	end

	table.insert(cb[trigger], fn)
end

beerchat.execute_callbacks = function(trigger, ...)
	local cb_list = beerchat.cb[trigger]
	if not cb_list then
		print('Error: Invalid trigger argument for beerchat.execute_callbacks')
		-- This is internal error / dev error, stop processing current event
		return false
	end
	local arg = {...}
	if arg == nil then
		print('Error: Missing arguments for beerchat.execute_callbacks')
		-- This is internal error / dev error, stop processing current event
		return false
	end
	for _,fn in ipairs(cb_list) do
		local result, msg = fn(unpack(arg))
		if result ~= nil then
			return result, msg
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
