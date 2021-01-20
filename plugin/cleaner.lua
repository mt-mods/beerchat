
beerchat.register_callback('on_receive', function(msg_data)
	msg_data.message = msg_data.message:gsub('%c','')
end)

beerchat.register_callback('on_http_receive', function(msg_data)
	-- Trim spaces and newlines, add ">" to mark newlines in incoming message
	msg_data.message = msg_data.message:gsub('%s+$',''):gsub('(%s)%s+','%1'):gsub('[\r\n]','\n  > ')
end)
