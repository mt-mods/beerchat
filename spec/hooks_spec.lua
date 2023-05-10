require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

sourcefile("init")

describe("Hooks", function()

	local SX = Player("SX", { shout = 1 })
	local Sam = Player("Sam", { shout = 1 })
	local Doe = Player("Doe", { shout = 1 })

	-- Use custom event handler to count on_receive calls
	local call_count = {}
	local function test(desc, msg, event, expected_count)
		local assert_msg = '%s called %d times, expected %d times. Message: "%s"'
		if not call_count[event] then
			call_count[event] = 0
			beerchat.register_callback(event, function()
				call_count[event] = call_count[event] + 1
			end)
		end
		it(desc.." "..msg, function()
			SX:send_chat_message(msg)
			local temp_count = call_count[event]
			call_count[event] = 0
			assert(temp_count == expected_count, assert_msg:format(event, temp_count, expected_count, msg))
		end)
	end

	local function describemethod(event, fn)
		describe(event, fn(event))
	end

	setup(function()
		mineunit:execute_on_joinplayer(SX)
		mineunit:execute_on_joinplayer(Sam)
		mineunit:execute_on_joinplayer(Doe)
	end)

	teardown(function()
		mineunit:execute_on_leaveplayer(Doe)
		mineunit:execute_on_leaveplayer(Sam)
		mineunit:execute_on_leaveplayer(SX)
	end)

	describemethod("on_receive", function(evt) return function()
		test("executed once for", "default message", evt, 1)
		test("executed once for", "#main test message", evt, 1)
		test("executed once for", "$ test message", evt, 1)
		test("executed once for", "/me test message", evt, 1)
		test("executed once for", "/whis test message", evt, 1)
		test("executed once for", "@Sam test message", evt, 1)
		test("executed once for", "/msg Sam test message", evt, 1)
	end end)

	describemethod("before_send", function(evt) return function()
		test("executed once/player for", "default message", evt, 3)
		test("executed once/player for", "#main test message", evt, 3)
		test("executed once/player for", "$ test message", evt, 3)
		test("executed once/player for", "/me test message", evt, 3)
		test("executed once/player for", "/whis test message", evt, 3)
		test("not executed for", "@Sam test message", evt, 0)
		test("not executed for", "/msg Sam test message", evt, 0)
	end end)

	describemethod("before_send_on_channel", function(evt) return function()
		test("executed once for", "default message", evt, 1)
		test("executed once for", "#main test message", evt, 1)
		test("not executed for", "$ test message", evt, 0)
		test("not executed once for", "/me test message", evt, 0)
		test("not executed for", "/whis test message", evt, 0)
		test("not executed for", "@Sam test message", evt, 0)
		test("not executed for", "/msg Sam test message", evt, 0)
	end end)

	describemethod("on_send_on_channel", function(evt) return function()
		test("executed once/player for", "default message", evt, 3)
		test("executed once/player for", "#main test message", evt, 3)
		test("not executed for", "$ test message", evt, 0)
		test("not executed once for", "/me test message", evt, 0)
		test("not executed for", "/whis test message", evt, 0)
		test("not executed for", "@Sam test message", evt, 0)
		test("not executed for", "/msg Sam test message", evt, 0)
	end end)

end)
