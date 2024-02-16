require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

describe("Mod initialization", function()

	it("Wont crash", function()
		sourcefile("init")
	end)

end)

describe("Core functionality", function()

	local M = function(s) return require("luassert.match").matches(s) end
	local SX = Player("SX", { shout = 1 })

	setup(function()
		beerchat.channels["testchannel"] = { owner = "beerholder", color = beerchat.default_channel_color }
		beerchat.channels["testchannel2"] = { owner = "SX", color = beerchat.default_channel_color }
		mineunit:execute_on_joinplayer(SX)
	end)

	teardown(function()
		mineunit:execute_on_leaveplayer(SX)
	end)

	it("sends messages", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("Everyone ignore me, this is just a test")
		assert.spy(minetest.chat_send_player).called_with("SX", M("Everyone ignore me, this is just a test"))
	end)

	it("creates channel", function()
		SX:send_chat_message("/cc foo")
		assert.not_nil(beerchat.channels["foo"])
	end)

	it("joins channel", function()
		assert.is_nil(beerchat.playersChannels["SX"]["testchannel"])
		SX:send_chat_message("/jc testchannel")
		assert.not_nil(beerchat.playersChannels["SX"]["testchannel"])
	end)

	it("deletes channel", function()
		SX:send_chat_message("/dc foo")
		assert.is_nil(beerchat.channels["foo"])
	end)

	it("lists channels", function()
		SX:send_chat_message("/jc testchannel")
		SX:send_chat_message("/jc testchannel2")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/mc")
		assert.spy(minetest.chat_send_player).called_with("SX", M("testchannel.+testchannel"))
	end)

	it("lists channel information", function()
		SX:send_chat_message("/jc testchannel")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/mc testchannel")
		assert.spy(minetest.chat_send_player).called_with("SX", M("beerholder"))
	end)

end)
