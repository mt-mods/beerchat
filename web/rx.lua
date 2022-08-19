local http = ...
local recv_loop

local function handle_data(data)
	if not data or not data.username or not data.text or not data.gateway or not data.protocol then
		return
	end

	if not beerchat.execute_callbacks('on_http_receive', data) then
		return
	end

	local name = data.username .. "@" .. data.protocol
	if data.event == "user_action" then
		-- "/me" message, TODO: use format and helper in "plugin/me.lua"
		beerchat.send_on_channel(name, data.gateway, data.text)
	elseif data.event == "join_leave" then
		-- join/leave message, from irc for example
		beerchat.send_on_channel(name, data.gateway, data.text)
	else
		-- regular message
		beerchat.send_on_channel(name, data.gateway, data.text)
	end
end


recv_loop = function()
	http.fetch({
		url = beerchat.url .. "/api/messages",
		timeout = 30,
	}, function(res)
		if res.succeeded and res.code == 200 and res.data then
			local data = minetest.parse_json(res.data)
			if not data then
				minetest.log("error", "[beerchat] content parsing error: " .. dump(res.data))
				minetest.after(5, recv_loop)
				return
			end

			if #data > 0 then
				-- array received
				for _, item in ipairs(data) do
					handle_data(item)
				end
			end

			minetest.after(0.5, recv_loop)
		else
			-- ignore errors
			minetest.log("error", "[beerchat] http request to " ..
				beerchat.url .. " failed with code " .. res.code)

			minetest.after(5, recv_loop)
		end

	end)
end

-- start loop
recv_loop()
