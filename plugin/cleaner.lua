
beerchat.register_callback('on_receive', function(msg_data)
	msg_data.message = msg_data.message:gsub('%c','')
end)

beerchat.register_callback('on_http_receive', function(msg_data)
	msg_data.message = msg_data.message:gsub('\n','\n  > ')
end)
