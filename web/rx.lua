
local http = beerchat.http
local recv_loop

function handle_data(data)
	if not data or not data.channel or not data.username or not data.message then
		return
	end

	if data.direct then
		-- direct message to bot
		local playername = data.username .. "@Remote"
		-- TODO: /login command over irc and name mapping
		local success, msg = beerchat.executor(data.message, playername)

		-- TODO return values
		return success, msg
	end

	local name = data.username .. "@Remote"
	beerchat.send_on_channel(name, data.channel, data.message)
end


recv_loop = function()
	http.fetch({
		url = beerchat.url,
		timeout = 30,
	}, function(res)
		if res.succeeded and res.code == 200 then
			local data = minetest.parse_json(res.data)
			handle_data(data)
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
