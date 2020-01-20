
local http = beerchat.http
local recv_loop

function handle_data(data)
	if not data or not data.source or not data.target
		or not data.message or not data.source_system then
		return
	end

	-- TODO: "direct" / pm / system-exec message
	local name = data.source .. "@" .. data.source_system
	beerchat.send_on_channel(name, data.target, data.message)
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
