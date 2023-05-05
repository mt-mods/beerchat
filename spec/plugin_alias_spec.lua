require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

sourcefile("init")

describe("Alias", function()

	local ANY = require("luassert.match")._

	local SX = Player("SX", { shout = 1, ban = 1, [beerchat.admin_priv] = 1 })
	local Sam = Player("Sam", { shout = 1 })
	local Doe = Player("Doe", { shout = 1 })

	setup(function()
		mineunit:execute_on_joinplayer(SX)
		mineunit:execute_on_joinplayer(Sam)
		mineunit:execute_on_joinplayer(Doe)
		-- Channel set 1
		SX:send_chat_message("/cc #alias-main")
		SX:send_chat_message("/cc #alias-main2")
		-- Channel set 2
		SX:send_chat_message("/cc #aliastest1")
		SX:send_chat_message("/cc #alias-aliastest1")
		-- Channel set 3
		SX:send_chat_message("/cc #aliastest2")
		SX:send_chat_message("/cc #alias-aliastest2")
		-- Channel set 4
		SX:send_chat_message("/cc #keepalias")
		SX:send_chat_message("/cc #alias1-keepalias")
		SX:send_chat_message("/cc #alias2-keepalias")
	end)

	teardown(function()
		mineunit:execute_on_leaveplayer(Doe)
		mineunit:execute_on_leaveplayer(Sam)
		mineunit:execute_on_leaveplayer(SX)
	end)

	it("/channel-alias without arguments", function()
		SX:send_chat_message("/channel-alias")
	end)

	it("create alias", function()
		SX:send_chat_message("/channel-alias #alias-main #main")
	end)

	it("create alias invalid channel", function()
		SX:send_chat_message("/channel-alias #channel-that-does-not-exist #main")
		SX:send_chat_message("/channel-alias #alias-main #channel-that-does-not-exist")
	end)

	it("create alias to alias", function()
		SX:send_chat_message("/channel-alias #alias-main2 #alias-main")
	end)

	it("resolve alias", function()
		SX:send_chat_message("/channel-alias #alias-main")
	end)

	it("resolve alias normal channel", function()
		SX:send_chat_message("/channel-alias #main")
	end)

	it("resolve alias invalid channel", function()
		SX:send_chat_message("/channel-alias #channel-that-does-not-exist")
	end)

	it("remove alias", function()
		SX:send_chat_message("/channel-unalias #alias-main")
	end)

	it("remove alias invalid channel", function()
		SX:send_chat_message("/channel-unalias #channel-that-does-not-exist")
		SX:send_chat_message("/channel-unalias #alias-main")
		SX:send_chat_message("/channel-unalias #main")
	end)

	it("channel switch", function()
		-- Prepare
		SX:send_chat_message("/channel-alias #alias1-keepalias #keepalias")
		SX:send_chat_message("/channel-alias #alias2-keepalias #keepalias")
		-- Test
		SX:send_chat_message("#keepalias")
		assert.equal(beerchat.get_player_channel("SX"), "keepalias")
		SX:send_chat_message("#alias1-keepalias")
		assert.equal(beerchat.get_player_channel("SX"), "keepalias")
		SX:send_chat_message("#alias2-keepalias")
		assert.equal(beerchat.get_player_channel("SX"), "keepalias")
	end)

	it("delivers messages 1", function()
		-- Prepare
		Sam:send_chat_message("#aliastest1")
		Doe:send_chat_message("#alias-aliastest1")
		SX:send_chat_message("/channel-alias #alias-aliastest1 #aliastest1")
		-- Test
		assert.equal(beerchat.get_player_channel("Sam"), "aliastest1")
		assert.equal(beerchat.get_player_channel("Doe"), "aliastest1")
		spy.on(beerchat, "execute_callbacks")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("#aliastest1 Test message to #aliastest1")
		SX:send_chat_message("#alias-aliastest1 Test message to #alias-aliastest1")
		assert.spy(beerchat.execute_callbacks).was.called_with("before_send", "SX", ANY, ANY)
		assert.spy(beerchat.execute_callbacks).was.called_with("before_send", "Sam", ANY, ANY)
		assert.spy(beerchat.execute_callbacks).was.called_with("before_send", "Doe", ANY, ANY)
		assert.spy(minetest.chat_send_player).was.called(3 * 2) -- 3 players, 2 messages
	end)

	it("delivers messages 2", function()
		-- Prepare
		SX:send_chat_message("/channel-alias #alias-aliastest2 #aliastest2")
		Sam:send_chat_message("#aliastest2")
		Doe:send_chat_message("#alias-aliastest2")
		-- Test
		assert.equal(beerchat.get_player_channel("Sam"), "aliastest2")
		assert.equal(beerchat.get_player_channel("Doe"), "aliastest2")
		spy.on(beerchat, "execute_callbacks")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("#aliastest2 Test message to #aliastest2")
		SX:send_chat_message("#alias-aliastest2 Test message to #alias-aliastest2")
		assert.spy(beerchat.execute_callbacks).was.called_with("before_send", "SX", ANY, ANY)
		assert.spy(beerchat.execute_callbacks).was.called_with("before_send", "Sam", ANY, ANY)
		assert.spy(beerchat.execute_callbacks).was.called_with("before_send", "Doe", ANY, ANY)
		assert.spy(minetest.chat_send_player).was.called(3 * 2) -- 3 players, 2 messages
	end)

end)
