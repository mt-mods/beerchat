require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

sourcefile("init")

describe("Hooks", function()

	local SX = Player("SX", { shout = 1 })

	-- Use custom event handler to count on_receive calls
	local assert_msg = '%s called %d times, expected %d times. Message: "%s"'
	local call_count = {}
	local function test(event, message, count)
		if not call_count[event] then
			call_count[event] = 0
			beerchat.register_callback(event, function()
				call_count[event] = call_count[event] + 1
			end)
        end
		SX:send_chat_message(message)
		local temp_count = call_count[event]
		call_count[event] = 0
		assert(temp_count == count, assert_msg:format(event, temp_count, count, message))
	end

	setup(function()
		mineunit:execute_on_joinplayer(SX)
	end)

	teardown(function()
		mineunit:execute_on_leaveplayer(SX)
	end)

	describe("on_receive", function()

		local method = "on_receive"

		it("executed once for default message", function()
			test(method, "always executed once test", 1)
		end)

		it("executed once for # message", function()
			test(method, "#main always executed once test", 1)
		end)

		it("executed once for $ message", function()
			test(method, "$ always executed once test", 1)
		end)

		it("executed once for @ message", function()
			test(method, "@SX always executed once test", 1)
		end)

		it("executed once for /msg message", function()
			test(method, "/msg SX always executed once test", 1)
		end)

		it("executed once for /me message", function()
			test(method, "/me always executed once test", 1)
		end)

		it("executed once for /whis message", function()
			test(method, "/whis always executed once test", 1)
		end)

	end)

	describe("before_send", function()

		local method = "before_send"

		it("executed once for default message", function()
			test(method, "always executed once test", 1)
		end)

		it("executed once for # message", function()
			test(method, "#main always executed once test", 1)
		end)

		it("executed once for $ message", function()
			test(method, "$ always executed once test", 1)
		end)

		it("executed once for /me message", function()
			test(method, "/me always executed once test", 1)
		end)

		it("executed once for /whis message", function()
			test(method, "/whis always executed once test", 1)
		end)

		it("never executed for @ messages", function()
			test(method, "@SX never executed test", 0)
		end)

		it("never executed for /msg messages", function()
			test(method, "/msg SX never executed test", 0)
		end)

	end)

end)
