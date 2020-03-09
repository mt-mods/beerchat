
local http = beerchat.http
local recv_loop

function handle_data(data)
	if not data or not data.username or not data.message or not data.name then
		return
	end

	local name = data.username .. "@" .. data.name

	if data.channel and data.channel ~= "" then
		-- channel message
		beerchat.send_on_channel(name, data.channel, data.message)

	elseif data.target_name == "minetest" then
			-- direct message
			local success, msg = beerchat.executor(data.message, name)

			if not success and not msg then
				-- failed without command
				msg = "Command failed!"
			end

			if not msg then
				-- no result, ignore
				return
			end

			local tx_data = {
				target_name = data.name,
				target_username = data.username,
				message = msg
			}

			local json = minetest.write_json(tx_data)

			http.fetch({
				url = beerchat.url,
				extra_headers = { "Content-Type: application/json" },
				timeout = 5,
				post_data = json
			}, function()
				-- ignore errors
			end)
	end
end


recv_loop = function()
	http.fetch({
		url = beerchat.url,
		timeout = 30,
	}, function(res)
		if res.succeeded and res.code == 200 then
			local data = minetest.parse_json(res.data)
			if #data > 0 then
				-- array received
				for _, item in ipairs(data) do
					handle_data(item)
				end
			else
				-- single item received
				handle_data(data)
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
