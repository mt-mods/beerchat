require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

sourcefile("init")

describe("Whisper", function()

	local SX = Player("SX", { shout = 1 })

	setup(function()
		mineunit:execute_on_joinplayer(SX)
	end)

	teardown(function()
		mineunit:execute_on_leaveplayer(SX)
	end)

	it("whispers", function()
		spy.on(beerchat, "send_message")
		SX:send_chat_message("$ Everyone ignore me, this is just a test")
		assert.spy(beerchat.send_message).was.called()
	end)

end)
