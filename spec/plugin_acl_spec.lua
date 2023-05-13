require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")
mineunit("auth")

sourcefile("init")

-- Utility functions to safely clear tables / beerchat data
local function clear_table(t) for k in pairs(t) do t[k] = nil end end
local function reset_beerchat()
	clear_table(beerchat.channels)
	clear_table(beerchat.playersChannels)
	clear_table(beerchat.currentPlayerChannel)
	beerchat.channels[beerchat.main_channel_name] = { owner = "SX", color = beerchat.default_channel_color }
end
local TEST_CHANNEL_INDEX = {}
local function NEXT_TEST_CHANNEL_NAME(prefix)
	TEST_CHANNEL_INDEX[prefix] = TEST_CHANNEL_INDEX[prefix] and (TEST_CHANNEL_INDEX[prefix] + 1) or 1
	return prefix .. tostring(TEST_CHANNEL_INDEX[prefix])
end

describe("ACL basic behavior", function()

	local M = function(s) return require("luassert.match").matches(s) end
	local ANY = require("luassert.match")._

	-- Matcher: operator invited other player to join chat channel
	local function INVITED(name, role) return M("[Ii]nvite .+"..name..".+"..role) end
	-- Matcher: someone inivites you to join chat channel
	local function INVITES(name, channel) return M(name..".+invited .+#"..channel:gsub("(%-)", "%%%1")) end

	-- Test players, reinitialized for each test
	local SX, Sam

	before_each(function()
		-- Reset all test channels
		beerchat.channels["acl-password"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-password-fail"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-invalid-name"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-invalid-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-fallback-read-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-fallback-default-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-fallback-deny-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-default-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-deny-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-owner-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-manager-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-write-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-read-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-update-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-update-privilege-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-delete-role"] = { owner = "SX", color = beerchat.default_channel_color }
		beerchat.channels["acl-chat"] = { owner = "SX", color = beerchat.default_channel_color }
		-- Recreate players for fresh data
		SX = Player("SX", { shout = 1 })
		Sam = Player("Sam", { shout = 1 })
		-- Join players
		mineunit:execute_on_joinplayer(SX)
		mineunit:execute_on_joinplayer(Sam)
		-- Set player channels
		beerchat.set_player_channel("SX", "main")
		beerchat.set_player_channel("Sam", "main")
	end)

	after_each(function()
		-- Remove players and reset test channels
		mineunit:execute_on_leaveplayer(Sam)
		mineunit:execute_on_leaveplayer(SX)
		Sam, SX = nil, nil
		reset_beerchat()
	end)

	it("checks password", function()
		SX:send_chat_message("/cc #acl-password,qwerty")
		spy.on(minetest, "chat_send_player")
		-- Initiate password protected join, it should ask for password and should not join the channel
		Sam:send_chat_message("/jc #acl-password")
		assert.spy(minetest.chat_send_player).called_with("Sam", M(".+assword.+lease.+assword"))
		assert.spy(minetest.chat_send_player).not_called_with("SX", ANY)
		assert.is_nil(beerchat.playersChannels["Sam"]["acl-password"])
		-- Joining succeeds and password is not visible to other players
		Sam:send_chat_message("qwerty")
		assert.spy(minetest.chat_send_player).not_called_with("SX", ANY)
		assert.not_nil(beerchat.playersChannels["Sam"]["acl-password"])
		-- Next messages will be visible to other players
		Sam:send_chat_message("qwerty")
		assert.spy(minetest.chat_send_player).called_with("SX", ANY)
	end)

	it("checks wrong password", function()
		SX:send_chat_message("/cc #acl-password-fail,qwerty")
		spy.on(minetest, "chat_send_player")
		-- Initiate password protected join, it should ask for password and should not join the channel
		Sam:send_chat_message("/jc #acl-password-fail")
		assert.spy(minetest.chat_send_player).called_with("Sam", M(".+assword.+lease.+assword"))
		assert.spy(minetest.chat_send_player).not_called_with("SX", ANY)
		assert.is_nil(beerchat.playersChannels["Sam"]["acl-password-fail"])
		-- Joining failed and password is not visible to other players
		Sam:send_chat_message("foobar")
		assert.spy(minetest.chat_send_player).not_called_with("SX", ANY)
		assert.is_nil(beerchat.playersChannels["Sam"]["acl-password-fail"])
		-- Next messages will be visible to other players
		Sam:send_chat_message("foobar")
		assert.spy(minetest.chat_send_player).called_with("SX", ANY)
	end)

	it("/ca handles invalid name", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-invalid-name ?")
		assert.spy(minetest.chat_send_player).called_with("SX", M("ERROR.+ident"))
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
	end)

	it("/ca handles invalid role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-invalid-role Sam ?")
		assert.spy(minetest.chat_send_player).called_with("SX", M("ERROR.+role"))
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
	end)

	it("/ca sets fallback role to write as default role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-fallback-default-role *")
		assert.spy(minetest.chat_send_player).called_with("SX", M("write.+#acl%-fallback%-default%-role"))
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
	end)

	it("/ca sets fallback role to read", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-fallback-read-role * read")
		assert.spy(minetest.chat_send_player).called_with("SX", M("read.+#acl%-fallback%-read%-role"))
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
	end)

	it("/ca uses write role as default role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-default-role Sam")
		assert.spy(minetest.chat_send_player).called_with("SX", INVITED("Sam", "write"))
		assert.spy(minetest.chat_send_player).called_with("Sam", INVITES("SX", "acl-default-role"))
	end)

	it("/ca sets deny role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-deny-role Sam deny")
		assert.spy(minetest.chat_send_player).not_called_with("SX", INVITED("Sam", "deny"))
		assert.spy(minetest.chat_send_player).not_called_with("Sam", INVITES("SX", "acl-deny-role"))
		assert.spy(minetest.chat_send_player).called_with("SX", M("[Dd]enied.+Sam.+acl%-deny%-role"))
	end)

	it("/ca sets owner role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-owner-role Sam owner")
		assert.spy(minetest.chat_send_player).called_with("SX", INVITED("Sam", "owner"))
		assert.spy(minetest.chat_send_player).called_with("Sam", INVITES("SX", "acl-owner-role"))
	end)

	it("/ca sets manager role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-manager-role Sam manager")
		assert.spy(minetest.chat_send_player).called_with("SX", INVITED("Sam", "manager"))
		assert.spy(minetest.chat_send_player).called_with("Sam", INVITES("SX", "acl-manager-role"))
	end)

	it("/ca sets write role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-write-role Sam write")
		assert.spy(minetest.chat_send_player).called_with("SX", INVITED("Sam", "write"))
		assert.spy(minetest.chat_send_player).called_with("Sam", INVITES("SX", "acl-write-role"))
	end)

	it("/ca sets read role", function()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-read-role Sam read")
		assert.spy(minetest.chat_send_player).called_with("SX", INVITED("Sam", "read"))
		assert.spy(minetest.chat_send_player).called_with("Sam", INVITES("SX", "acl-read-role"))
	end)

	it("/ca updates role", function()
		SX:send_chat_message("/ca #acl-update-role Sam read")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-update-role Sam manager")
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
		assert.spy(minetest.chat_send_player).called_with("SX", M("pdate.+manager"))
	end)

	it("/ca updates privilege role", function()
		SX:send_chat_message("/ca #acl-update-privilege-role $shout read")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-update-privilege-role $shout manager")
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
		assert.spy(minetest.chat_send_player).called_with("SX", M("pdate.+manager"))
	end)

	it("/ca removes role", function()
		SX:send_chat_message("/ca #acl-delete-role Sam manager")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca #acl-delete-role -d Sam")
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
		assert.spy(minetest.chat_send_player).called_with("SX", M("emoved.+elete"))
	end)

	it("read role allows reading messages", function()
		beerchat.set_player_channel("SX", "acl-chat")
		beerchat.set_player_channel("Sam", "acl-chat")
		SX:send_chat_message("/ca #acl-chat Sam read")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("Test message")
		-- Channel message allowed and delivered
		assert.spy(minetest.chat_send_player).called_with("Sam", M("Test message"))
		assert.spy(minetest.chat_send_player).called_with("SX", M("Test message"))
	end)

	it("read role disallows sending messages", function()
		beerchat.set_player_channel("SX", "acl-chat")
		beerchat.set_player_channel("Sam", "acl-chat")
		SX:send_chat_message("/ca #acl-chat Sam read")
		spy.on(minetest, "chat_send_player")
		Sam:send_chat_message("Test message")
		-- Channel message disallowed and player informed
		assert.spy(minetest.chat_send_player).not_called_with("SX", ANY)
		assert.spy(minetest.chat_send_player).not_called_with("Sam", M("Test message"))
		assert.spy(minetest.chat_send_player).called_with("Sam", ANY)
	end)

	it("default fallback role allows sending messages", function()
		SX:send_chat_message("/ca #acl-fallback-default-role *")
		beerchat.set_player_channel("SX", "acl-fallback-default-role")
		beerchat.set_player_channel("Sam", "acl-fallback-default-role")
		-- Channel message disallowed and player informed
		spy.on(minetest, "chat_send_player")
		Sam:send_chat_message("Test message")
		assert.spy(minetest.chat_send_player).called_with("SX", M("Test message"))
		assert.spy(minetest.chat_send_player).called_with("Sam", M("Test message"))
	end)

	it("read fallback disallows sending messages", function()
		SX:send_chat_message("/ca #acl-fallback-read-role * read")
		beerchat.set_player_channel("SX", "acl-fallback-read-role")
		beerchat.set_player_channel("Sam", "acl-fallback-read-role")
		-- Channel message disallowed and player informed
		spy.on(minetest, "chat_send_player")
		Sam:send_chat_message("Test message")
		assert.spy(minetest.chat_send_player).not_called_with("SX", ANY)
		assert.spy(minetest.chat_send_player).not_called_with("Sam", M("Test message"))
		assert.spy(minetest.chat_send_player).called_with("Sam", M("ERROR.+write.+acl%-fallback%-read%-role"))
	end)

	it("read fallback role allows joining channel", function()
		SX:send_chat_message("/ca #acl-fallback-read-role * read")
		-- Channel message disallowed and player informed
		spy.on(minetest, "chat_send_player")
		Sam:send_chat_message("/jc #acl-fallback-read-role")
		assert.spy(minetest.chat_send_player).not_called_with("Sam", M("ERROR"))
		assert.not_nil(beerchat.playersChannels["Sam"]["acl-fallback-read-role"])
	end)

	it("deny fallback role disallows joining", function()
		SX:send_chat_message("/ca #acl-fallback-deny-role * deny")
		-- Channel message disallowed and player informed
		spy.on(minetest, "chat_send_player")
		Sam:send_chat_message("/jc #acl-fallback-deny-role")
		assert.spy(minetest.chat_send_player).called_with("Sam", M("ERROR.+access.+acl%-fallback%-deny%-role"))
		assert.not_nil(beerchat.playersChannels["Sam"]["main"])
		assert.is_nil(beerchat.playersChannels["Sam"]["acl-fallback-deny-role"])
	end)

	it("deny fallback role disallows reading messages", function()
		beerchat.set_player_channel("SX", "acl-fallback-deny-role")
		beerchat.set_player_channel("Sam", "acl-fallback-deny-role")
		SX:send_chat_message("/ca #acl-fallback-deny-role * deny")
		-- Channel message disallowed and player informed
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("Test message")
		assert.spy(minetest.chat_send_player).called_with("SX", M("Test message"))
		assert.spy(minetest.chat_send_player).not_called_with("SX", M("ERROR"))
		assert.spy(minetest.chat_send_player).not_called_with("Sam", M("Test message"))
		assert.spy(minetest.chat_send_player).not_called_with("Sam", M("ERROR"))
	end)

	it("deny fallback role disallows sending messages", function()
		beerchat.set_player_channel("SX", "acl-fallback-deny-role")
		beerchat.set_player_channel("Sam", "acl-fallback-deny-role")
		SX:send_chat_message("/ca #acl-fallback-deny-role * deny")
		-- Channel message disallowed and player informed
		spy.on(minetest, "chat_send_player")
		Sam:send_chat_message("Test message")
		assert.spy(minetest.chat_send_player).not_called_with("SX", M("Test message"))
		assert.spy(minetest.chat_send_player).not_called_with("Sam", M("Test message"))
		assert.spy(minetest.chat_send_player).called_with("Sam", M("ERROR.+access.+acl%-fallback%-deny%-role"))
	end)

end)

describe("ACL chatcommand", function()

	local M = function(s) return require("luassert.match").matches(s) end
	local SX
	local function SendMessage(msg)
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message(msg)
	end

	local TEST_CHANNEL
	before_each(function()
		-- Recreate and join players for fresh data
		SX = Player("SX", { shout = 1 })
		mineunit:execute_on_joinplayer(SX)
		-- Create fresh test channel
		TEST_CHANNEL = NEXT_TEST_CHANNEL_NAME("#acl_chatcommand")
		SX:send_chat_message("/cc "..TEST_CHANNEL)
	end)

	after_each(function()
		-- Remove players and reset test channels
		mineunit:execute_on_leaveplayer(SX)
		SX = nil
		reset_beerchat()
	end)

	-- Usage: /ca <Channel Name> [[-d] <Identity> [Access Role]]

	it("rejects /ca", function()
		SendMessage("/ca")
		assert.spy(minetest.chat_send_player).called_with("SX", M("ERROR"))
	end)

	it("accepts /ca #test", function()
		SendMessage("/ca "..TEST_CHANNEL)
		assert.spy(minetest.chat_send_player).not_called_with("SX", M("ERROR"))
	end)

	it("rejects /ca #notchannel", function()
		SendMessage("/ca #notchannel")
		assert.spy(minetest.chat_send_player).called_with("SX", M("ERROR"))
	end)

	it("rejects /ca #test -d", function()
		SendMessage("/ca "..TEST_CHANNEL.." -d")
		assert.spy(minetest.chat_send_player).called_with("SX", M("ERROR"))
	end)

	it("rejects /ca #test @", function()
		SendMessage("/ca "..TEST_CHANNEL.." @")
		assert.spy(minetest.chat_send_player).called_with("SX", M("ERROR"))
	end)

	it("rejects /ca #test $", function()
		SendMessage("/ca "..TEST_CHANNEL.." $")
		assert.spy(minetest.chat_send_player).called_with("SX", M("ERROR"))
	end)

	it("accepts /ca #test *", function()
		SendMessage("/ca "..TEST_CHANNEL.." *")
		assert.spy(minetest.chat_send_player).not_called_with("SX", M("ERROR"))
	end)

	it("accepts /ca #test * manager", function()
		SendMessage("/ca "..TEST_CHANNEL.." * manager")
		assert.spy(minetest.chat_send_player).not_called_with("SX", M("ERROR"))
	end)

	it("accepts /ca #test SX", function()
		SendMessage("/ca "..TEST_CHANNEL.." *")
		assert.spy(minetest.chat_send_player).not_called_with("SX", M("ERROR"))
	end)

	it("accepts /ca #test SX manager", function()
		SendMessage("/ca "..TEST_CHANNEL.." * manager")
		assert.spy(minetest.chat_send_player).not_called_with("SX", M("ERROR"))
	end)

	it("rejects /ca #test SX notrole", function()
		SendMessage("/ca "..TEST_CHANNEL.." * notrole")
		assert.spy(minetest.chat_send_player).called_with("SX", M("ERROR"))
	end)

	it("accepts /ca #test $fly", function()
		SendMessage("/ca "..TEST_CHANNEL.." $fly")
		assert.spy(minetest.chat_send_player).not_called_with("SX", M("ERROR"))
	end)

	it("accepts /ca #test $fly manager", function()
		SendMessage("/ca "..TEST_CHANNEL.." $fly manager")
		assert.spy(minetest.chat_send_player).not_called_with("SX", M("ERROR"))
	end)

	it("rejects /ca #test $banana", function()
		SendMessage("/ca "..TEST_CHANNEL.." $banana")
		assert.spy(minetest.chat_send_player).called_with("SX", M("ERROR"))
	end)

	it("rejects /ca #test $banana manager", function()
		SendMessage("/ca "..TEST_CHANNEL.." $banana manager")
		assert.spy(minetest.chat_send_player).called_with("SX", M("ERROR"))
	end)

	it("accepts /ca #test -d *", function()
		SendMessage("/ca "..TEST_CHANNEL.." -d *")
		assert.spy(minetest.chat_send_player).not_called_with("SX", M("ERROR"))
	end)

end)

describe("ACL integration", function()

	-- Test players, reinitialized for each test
	local SX, Sam, Joe

	-- Matchers / helpers
	local M = function(s) return require("luassert.match").matches(s) end
	local ANY = require("luassert.match")._
	local FROM_SX = M("From .*SX")
	local FROM_SAM = M("From .*Sam")
	local FROM_JOE = M("From .*Joe")
	local DENIED = M("ERROR")
	local function SendMessages()
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("From SX")
		Sam:send_chat_message("From Sam")
		Joe:send_chat_message("From Joe")
	end
	local function Esc(s)
		return s:gsub("([^a-zA-Z0-9_])", "%%%1")
	end

	setup(function()
		minetest.register_privilege("privilegename", "Test privilege")
	end)

	local TEST_CHANNEL
	before_each(function()
		-- Recreate and join players for fresh data
		SX = Player("SX", { shout = 1 })
		Sam = Player("Sam", { shout = 1, fly = 1 })
		Joe = Player("Joe", { shout = 1, fast = 1 })
		mineunit:execute_on_joinplayer(SX)
		mineunit:execute_on_joinplayer(Sam)
		mineunit:execute_on_joinplayer(Joe)
		-- Create fresh test channel and switch to it
		TEST_CHANNEL = NEXT_TEST_CHANNEL_NAME("#acl_integration")
		SX:send_chat_message("/cc "..TEST_CHANNEL)
		SX:send_chat_message(TEST_CHANNEL)
		Sam:send_chat_message(TEST_CHANNEL)
		Joe:send_chat_message(TEST_CHANNEL)
	end)

	after_each(function()
		-- Remove players and reset test channels
		mineunit:execute_on_leaveplayer(Joe)
		mineunit:execute_on_leaveplayer(Sam)
		mineunit:execute_on_leaveplayer(SX)
		SX, Sam, Joe = nil, nil, nil
		reset_beerchat()
	end)

	it("passess test 1", function()
		-- ACL: SX=channel-owner (no ACL)
		SendMessages()
		-- Everyone can send and receive
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("Sam", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("Sam", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_JOE)
		assert.spy(minetest.chat_send_player).called_with("Sam", FROM_JOE)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_JOE)
	end)

	it("passess test 2", function()
		-- ACL: SX=channel-owner SX=deny
		SX:send_chat_message("/ca "..TEST_CHANNEL.." SX deny")
		SendMessages()
		-- Everyone can send and receive, main channel owner (not ACL owner) cannot override their own ownership
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("Sam", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("Sam", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_JOE)
		assert.spy(minetest.chat_send_player).called_with("Sam", FROM_JOE)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_JOE)
	end)

	it("passess test 3", function()
		-- ACL: SX=channel-owner Sam=read Joe=write
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Sam read")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Joe write")
		SendMessages()
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("Sam", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_SX)
		assert.spy(minetest.chat_send_player).not_called_with("SX", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("Sam", DENIED)
		assert.spy(minetest.chat_send_player).not_called_with("Joe", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_JOE)
		assert.spy(minetest.chat_send_player).called_with("Sam", FROM_JOE)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_JOE)
	end)

	it("passess test 4", function()
		-- ACL: SX=channel-owner *=read Joe=write
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * read")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Joe write")
		SendMessages()
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("Sam", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_SX)
		assert.spy(minetest.chat_send_player).not_called_with("SX", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("Sam", DENIED)
		assert.spy(minetest.chat_send_player).not_called_with("Joe", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_JOE)
		assert.spy(minetest.chat_send_player).called_with("Sam", FROM_JOE)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_JOE)
	end)

	it("passess test 5", function()
		-- ACL: SX=channel-owner *=deny Joe=read
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * deny")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Joe read")
		SendMessages()
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_SX)
		assert.spy(minetest.chat_send_player).not_called_with("Sam", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_SX)
		assert.spy(minetest.chat_send_player).not_called_with("SX", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("Sam", DENIED)
		assert.spy(minetest.chat_send_player).not_called_with("Joe", FROM_SAM)
		assert.spy(minetest.chat_send_player).not_called_with("SX", FROM_JOE)
		assert.spy(minetest.chat_send_player).not_called_with("Sam", FROM_JOE)
		assert.spy(minetest.chat_send_player).called_with("Joe", DENIED)
	end)

	it("passess test 6", function()
		-- ACL: SX=channel-owner *=deny Joe=read
		SX:send_chat_message("/ca "..TEST_CHANNEL.." SX deny")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Sam read")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $fly owner")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Joe write")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * read")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $fast manager")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Joe write")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * deny")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." -d $fly")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Joe read")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." -d Sam read")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." -d $fast")
		SendMessages()
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_SX)
		assert.spy(minetest.chat_send_player).not_called_with("Sam", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_SX)
		assert.spy(minetest.chat_send_player).not_called_with("SX", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("Sam", DENIED)
		assert.spy(minetest.chat_send_player).not_called_with("Joe", FROM_SAM)
		assert.spy(minetest.chat_send_player).not_called_with("SX", FROM_JOE)
		assert.spy(minetest.chat_send_player).not_called_with("Sam", FROM_JOE)
		assert.spy(minetest.chat_send_player).called_with("Joe", DENIED)
	end)

	it("passess test 7", function()
		-- ACL: SX=channel-owner *=deny $fast=read
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * deny")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $fast read")
		SendMessages()
		assert.spy(minetest.chat_send_player).called_with("SX", FROM_SX)
		assert.spy(minetest.chat_send_player).not_called_with("Sam", FROM_SX)
		assert.spy(minetest.chat_send_player).called_with("Joe", FROM_SX)
		assert.spy(minetest.chat_send_player).not_called_with("SX", FROM_SAM)
		assert.spy(minetest.chat_send_player).called_with("Sam", DENIED)
		assert.spy(minetest.chat_send_player).not_called_with("Joe", FROM_SAM)
		assert.spy(minetest.chat_send_player).not_called_with("SX", FROM_JOE)
		assert.spy(minetest.chat_send_player).not_called_with("Sam", FROM_JOE)
		assert.spy(minetest.chat_send_player).called_with("Joe", DENIED)
	end)

	it("passess test 8", function()
		-- ACL: SX=channel-owner *=deny
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * deny")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca "..TEST_CHANNEL)
		-- Check output sorting and formatting: privileges, player names, fallback
		assert.spy(minetest.chat_send_player).called_with("SX", M(
			"Identity Role\n" ..
			"%-+\n" .. Esc(
			"*        deny")
		))
		-- Other players shouldn't get any feedback from management actions
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
		assert.spy(minetest.chat_send_player).not_called_with("Joe", ANY)
	end)

	it("passess test 9", function()
		-- ACL: SX=channel-owner *=deny
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $privilegename deny")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca "..TEST_CHANNEL)
		-- Check output sorting and formatting: privileges, player names, fallback
		assert.spy(minetest.chat_send_player).called_with("SX", M(
			"Identity       Role\n" ..
			"%-+\n" .. Esc(
			"$privilegename deny")
		))
		-- Other players shouldn't get any feedback from management actions
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
		assert.spy(minetest.chat_send_player).not_called_with("Joe", ANY)
	end)

	it("passess test 10", function()
		-- ACL: SX=channel-owner *=deny $fast=read Sam=manager
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * deny")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $fast read")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Sam manager")
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca "..TEST_CHANNEL)
		-- Check output sorting and formatting: privileges, player names, fallback
		assert.spy(minetest.chat_send_player).called_with("SX", M(
			"Identity Role\n" ..
			"%-+\n" .. Esc(
			"$fast    read\n" ..
			"Sam      manager\n" ..
			"*        deny")
		))
		-- Other players shouldn't get any feedback from management actions
		assert.spy(minetest.chat_send_player).not_called_with("Sam", ANY)
		assert.spy(minetest.chat_send_player).not_called_with("Joe", ANY)
	end)

	it("passess test 11", function()
		-- ACL: SX=channel-owner *=deny $fast=read Joe=read
		-- Purpose of this test is to make sure that player name can be added
		-- even if player already has access through privilege role.
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * deny")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $fast read")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Joe read")
		-- Validate channel ACL: sorting, formatting, privileges, player names, fallback
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca "..TEST_CHANNEL)
		assert.spy(minetest.chat_send_player).called_with("SX", M(
			"Identity Role\n" ..
			"%-+\n" .. Esc(
			"$fast    read\n" ..
			"Joe      read\n" ..
			"*        deny")
		))
	end)

	it("passess test 12", function()
		-- ACL: SX=channel-owner *=deny $fast=read Joe=read
		-- Purpose of this test is to make sure that player name can be added
		-- even if player already has access through privilege role.
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * deny")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Joe read")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $fast read")
		-- Validate channel ACL: sorting, formatting, privileges, player names, fallback
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca "..TEST_CHANNEL)
		assert.spy(minetest.chat_send_player).called_with("SX", M(
			"Identity Role\n" ..
			"%-+\n" .. Esc(
			"$fast    read\n" ..
			"Joe      read\n" ..
			"*        deny")
		))
	end)

	it("passess test 13", function()
		-- ACL: SX=channel-owner *=deny $fast=read Joe=read
		-- Purpose of this test is to make sure that player name can be added
		-- even if player already has access through cached privilege role.
		Joe:send_chat_message("/lc "..TEST_CHANNEL)
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * deny")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $fast read")
		-- Initialize caches by reading ACLs once
		Joe:send_chat_message(TEST_CHANNEL)
		-- Add role that is already provided to Joe through $fast privilege
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Joe read")
		-- Validate channel ACL: sorting, formatting, privileges, player names, fallback
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca "..TEST_CHANNEL)
		assert.spy(minetest.chat_send_player).called_with("SX", M(
			"Identity Role\n" ..
			"%-+\n" .. Esc(
			"$fast    read\n" ..
			"Joe      read\n" ..
			"*        deny")
		))
	end)

	it("passess test 14", function()
		-- ACL: SX=channel-owner *=deny $fast=read Joe=read
		-- Purpose of this test is to make sure that player name can be added
		-- even if player already has access through cached privilege role.
		Joe:send_chat_message("/lc "..TEST_CHANNEL)
		SX:send_chat_message("/ca "..TEST_CHANNEL.." Joe read")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * deny")
		-- Initialize caches by reading ACLs once
		Joe:send_chat_message(TEST_CHANNEL)
		-- Add role that is already provided to Joe through player name
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $fast read")
		-- Validate channel ACL: sorting, formatting, privileges, player names, fallback
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca "..TEST_CHANNEL)
		assert.spy(minetest.chat_send_player).called_with("SX", M(
			"Identity Role\n" ..
			"%-+\n" .. Esc(
			"$fast    read\n" ..
			"Joe      read\n" ..
			"*        deny")
		))
	end)

	it("passess test 15", function()
		-- ACL: SX=channel-owner *=deny $fast=read Joe=read
		-- Purpose of this test is to make sure that player name can be added
		-- even if player already has access through privilege role.
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * deny")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $fast read")
		-- Add role that is already provided to Joe through another privilege role
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $shout write")
		-- Validate channel ACL: sorting, formatting, privileges, player names, fallback
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca "..TEST_CHANNEL)
		assert.spy(minetest.chat_send_player).called_with("SX", M(
			"Identity Role\n" ..
			"%-+\n" .. Esc(
			"$fast    read\n" ..
			"$shout   write\n" ..
			"*        deny")
		))
	end)

	it("passess test 16", function()
		-- ACL: SX=channel-owner *=deny $fast=read Joe=read
		-- Purpose of this test is to make sure that player name can be added
		-- even if player already has access through cached privilege role.
		Joe:send_chat_message("/lc "..TEST_CHANNEL)
		SX:send_chat_message("/ca "..TEST_CHANNEL.." * deny")
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $fast read")
		-- Initialize caches by reading ACLs once
		Joe:send_chat_message(TEST_CHANNEL)
		-- Add role that is already provided to Joe through another privilege role
		SX:send_chat_message("/ca "..TEST_CHANNEL.." $shout write")
		-- Validate channel ACL: sorting, formatting, privileges, player names, fallback
		spy.on(minetest, "chat_send_player")
		SX:send_chat_message("/ca "..TEST_CHANNEL)
		assert.spy(minetest.chat_send_player).called_with("SX", M(
			"Identity Role\n" ..
			"%-+\n" .. Esc(
			"$fast    read\n" ..
			"$shout   write\n" ..
			"*        deny")
		))
	end)

end)