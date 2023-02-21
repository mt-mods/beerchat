require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")
mineunit("auth")

sourcefile("init")

-- Players, initialized in test environment setup functions
local SX, XX, XX_channel, XX_name
local XX_count = 0

local function do_setup()
	SX = Player("SX", { shout = 1, ban = 1 })
	mineunit:execute_on_joinplayer(SX)
	assert.equals("main", beerchat.get_player_channel("SX"))
end

local function do_teardown()
	mineunit:execute_on_leaveplayer(SX)
end

local function do_before_each()
	XX_count = XX_count + 1
	XX_name = "XX"..XX_count
	XX = Player(XX_name, { shout = 1 })
	mineunit:execute_on_joinplayer(XX)
	XX_channel = beerchat.get_player_channel(XX_name)
end

local function do_after_each()
	mineunit:execute_on_leaveplayer(XX)
	XX = nil
	XX_name = nil
	XX_channel = nil
end

describe("channel_ban command", function()

	setup(do_setup)
	teardown(do_teardown)
	before_each(do_before_each)
	after_each(do_after_each)

	it("records channel ban", function()
		assert.is_false(beerchat.ban.is_player_banned(XX_channel, XX_name))
		SX:send_chat_message("/channel_ban "..XX_name)
		assert.is_true(beerchat.ban.is_player_banned(XX_channel, XX_name))
	end)

	it("handles players that are already banned", function()
		SX:send_chat_message("/channel_ban "..XX_name)
		SX:send_chat_message("/channel_ban "..XX_name)
		assert.is_true(beerchat.ban.is_player_banned(XX_channel, XX_name))
	end)

	it("handles invalid player name", function()
		pending("Mineunit auth handler raises exception for invalid names, this test wont work")
		SX:send_chat_message("/channel_ban ***")
	end)

	it("handles empty player name", function()
		SX:send_chat_message("/channel_ban")
		assert.equals("main", beerchat.get_player_channel("SX"))
		assert.is_false(beerchat.ban.is_player_banned("main", "SX"))
	end)

end)

describe("channel_unban command", function()

	setup(do_setup)
	teardown(do_teardown)
	before_each(do_before_each)
	after_each(do_after_each)

	it("handles invalid player name", function()
		SX:send_chat_message("/channel_unban ***")
	end)

	it("handles empty player name", function()
		SX:send_chat_message("/channel_unban")
	end)

	it("handles players that are not banned", function()
		SX:send_chat_message("/channel_unban "..XX_name)
		assert.equals(XX_channel, beerchat.get_player_channel(XX_name))
		assert.is_false(beerchat.ban.is_player_banned(XX_channel, XX_name))
	end)

end)
