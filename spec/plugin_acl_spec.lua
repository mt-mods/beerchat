require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

sourcefile("init")

describe("ACL", function()

	local M = function(s) return require("luassert.match").matches(s) end
	local ANY = require("luassert.match")._
	assert:register("matcher", "has_channel", function(_, args)
		return function(msg)
			return type(msg) == "table" and msg.channel == args[1]
		end
	end)
	local CHANNEL = require("luassert.match").has_channel

	local SX = Player("SX", { shout = 1 })
	local Sam = Player("Sam", { shout = 1 })

	setup(function()
		mineunit:execute_on_joinplayer(SX)
		mineunit:execute_on_joinplayer(Sam)
		-- Test channels
		beerchat.channels["acl-password"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-default-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-owner-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-manager-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-write-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-read-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-update-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-delete-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-chat"] = { owner = "SX", color = beerchat.default_channel_color }
	end)

	before_each(function()
		beerchat.set_player_channel("SX", "main")
		beerchat.set_player_channel("Sam", "main")
	end)

	teardown(function()
		mineunit:execute_on_leaveplayer(Sam)
		mineunit:execute_on_leaveplayer(SX)
	end)

	it("checks password", function()
		SX:send_chat_message("/cc #acl-password,qwerty")
		spy.on(minetest, "chat_send_player")
		-- Initiate password protected join, it should ask for password and should not join channel
		Sam:send_chat_message("/jc #acl-password")
		assert.spy(minetest.chat_send_player).called_with("Sam", M(".+assword.+lease.+assword"))
		assert.spy(minetest.chat_send_player).not_called_with("SX", ANY)
		assert.is_nil(beerchat.playersChannels["Sam"]["acl-password"])
		-- Password is not visible to other players
		Sam:send_chat_message("qwerty")
		assert.spy(minetest.chat_send_player).not_called_with("SX", ANY)
		assert.not_nil(beerchat.playersChannels["Sam"]["acl-password"])
		-- Next messages will be visible to other players
		Sam:send_chat_message("qwerty")
		assert.spy(minetest.chat_send_player).called_with("SX", ANY)
	end)

	it("/invite_channel sets default role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/invite_channel #acl-default-role Sam")
		assert.spy(minetest.chat_send_player).called_with("SX", M("Invite sent.+Sam"))
		assert.spy(minetest.chat_send_player).called_with("Sam", M("SX.+invite.+join.+channel"))
	end)

	it("/invite_channel sets owner role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/invite_channel #acl-owner-role Sam owner")
		assert.spy(minetest.chat_send_player).called_with("SX", M("Invite sent.+Sam"))
		assert.spy(minetest.chat_send_player).called_with("Sam", M("SX.+invite.+join.+channel"))
	end)

	it("/invite_channel sets manager role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/invite_channel #acl-manager-role Sam manager")
		assert.spy(minetest.chat_send_player).called_with("SX", M("Invite sent.+Sam"))
		assert.spy(minetest.chat_send_player).called_with("Sam", M("SX.+invite.+join.+channel"))
	end)

	it("/invite_channel sets write role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/invite_channel #acl-write-role Sam write")
		assert.spy(minetest.chat_send_player).called_with("SX", M("Invite sent.+Sam"))
		assert.spy(minetest.chat_send_player).called_with("Sam", M("SX.+invite.+join.+channel"))
	end)

	it("/invite_channel sets read role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/invite_channel #acl-read-role Sam read")
		assert.spy(minetest.chat_send_player).called_with("SX", M("Invite sent.+Sam"))
		assert.spy(minetest.chat_send_player).called_with("Sam", M("SX.+invite.+join.+channel"))
	end)

	it("/invite_channel updates role", function()
		SX:send_chat_message("/invite_channel #acl-update-role Sam read")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/invite_channel #acl-update-role Sam manager")
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
		assert.spy(minetest.chat_send_player).called_with("SX", M("update.+manager"))
	end)

	it("/invite_channel removes role", function()
		SX:send_chat_message("/invite_channel #acl-delete-role Sam manager")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/invite_channel #acl-delete-role -d Sam")
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
		assert.spy(minetest.chat_send_player).called_with("SX", M("emoved.+elete"))
	end)

	it("read role allows reading messages", function()
		beerchat.set_player_channel("SX", "acl-chat")
		beerchat.set_player_channel("Sam", "acl-chat")
		SX:send_chat_message("/channel_acl #acl-chat Sam read")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("Test message")
		-- Channel message allowed and delivered
		assert.spy(minetest.chat_send_player).called_with("Sam", M("Test message"))
		assert.spy(minetest.chat_send_player).called_with("SX", M("Test message"))
	end)

	it("read role disallows sending messages", function()
		beerchat.set_player_channel("SX", "acl-chat")
		beerchat.set_player_channel("Sam", "acl-chat")
		SX:send_chat_message("/channel_acl #acl-chat Sam read")
		spy.on(minetest, "chat_send_player")
		Sam:send_chat_message("Test message")
		-- Channel message disallowed and player informed
		assert.spy(minetest.chat_send_player).not_called_with("SX", ANY)
		assert.spy(minetest.chat_send_player).not_called_with("Sam", M("Test message"))
		assert.spy(minetest.chat_send_player).called_with("Sam", ANY)
	end)

end)
