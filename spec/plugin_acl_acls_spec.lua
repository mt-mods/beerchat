require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

describe("ACL/acls", function()

	-- Load bare acls.lua, assuming no dependencies other than channels table.
	_G.beerchat = {
		channels = {
			TEST = {}
		}
	}

	local acls
	local SX = Player("SX", { shout = 1, fast = 1 })
	setup(function() mineunit:execute_on_joinplayer(SX) end)
	teardown(function() mineunit:execute_on_leaveplayer(SX) end)
	before_each(function() acls = sourcefile("plugin/acl/acls")(nil, function() end) end)

	it("acls:set_role", function()
		acls:set_role("TEST", "SX", "read")
		assert.same(acls.data.TEST, { SX = "read" })
	end)

	it("acls:set_role privilege", function()
		acls:set_role("TEST", "$fast", "write")
		assert.same(acls.data.TEST, { ["$fast"] = "write" })
	end)

	it("acls:get_role", function()
		assert.is_nil(acls:get_role("TEST", "SX"))
	end)

	it("acls:get_role non player", function()
		assert.is_nil(acls:get_role("TEST", "?"))
	end)

	it("acls:get_privilege_role", function()
		assert.is_nil(acls:get_privilege_role("TEST", "SX"))
	end)

	it("acls:get_privilege_role non player", function()
		assert.is_nil(acls:get_privilege_role("TEST", "?"))
	end)

	it("acls:write_storage", function()
		acls:write_storage()
	end)

	it("acls:check_access", function()
		assert.is_nil(acls:check_access("TEST", "SX"))
	end)

	it("returns correct player role", function()
		acls:set_role("TEST", "SX", "deny")
		acls:set_role("TEST", "SX", "manager")
		assert.equals(acls:get_role("TEST", "SX"), "manager")
		acls:set_role("TEST", "SX", "deny")
		assert.equals(acls:get_role("TEST", "SX"), "deny")
	end)

	it("returns correct privilege role", function()
		acls:set_role("TEST", "$fast", "deny")
		acls:set_role("TEST", "$fast", "manager")
		assert.equals(acls:get_role("TEST", "SX"), "manager")
		acls:set_role("TEST", "$fast", "deny")
		assert.equals(acls:get_role("TEST", "SX"), "deny")
	end)

	it("acls:check_access deny", function()
		acls:set_role("TEST", "$fast", "deny")
		assert.is_false(acls:check_access("TEST", "SX"))
		assert.is_false(acls:check_access("TEST", "SX", "read"))
		assert.is_false(acls:check_access("TEST", "SX", "write"))
		assert.is_false(acls:check_access("TEST", "SX", "manager"))
		assert.is_false(acls:check_access("TEST", "SX", "owner"))
	end)

	it("acls:check_access write", function()
		acls:set_role("TEST", "$fast", "write")
		assert.is_nil(acls:check_access("TEST", "SX"))
		assert.is_nil(acls:check_access("TEST", "SX", "read"))
		assert.is_nil(acls:check_access("TEST", "SX", "write"))
		assert.is_false(acls:check_access("TEST", "SX", "manager"))
		assert.is_false(acls:check_access("TEST", "SX", "owner"))
	end)

end)
