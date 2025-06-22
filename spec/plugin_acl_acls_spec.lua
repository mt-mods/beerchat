require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")

describe("ACL/acls", function()

	local M = function(s) return require("luassert.match").matches(s) end

	-- Test bare acls.lua with privilege extension, assuming no dependencies other than channels table.
	_G.beerchat = {
		channels = {
			TEST = {}
		}
	}

	local acls
	local SX = Player("SX", { shout = 1, fast = 1 })
	setup(function() mineunit:execute_on_joinplayer(SX) end)
	teardown(function() mineunit:execute_on_leaveplayer(SX) end)
	before_each(function()
		acls = sourcefile("plugin/acl/acls")(nil, function() end)
		acls:register_provider("*", dofile("plugin/acl/players.lua"))
		acls:register_provider("$", dofile("plugin/acl/privileges.lua"))
	end)

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

	it("acls:get_role (privilege extension, empty roles)", function()
		local provider = acls:get_provider("$name")
		assert.not_nil(provider)
		assert.not_equals(acls:get_provider("name"), provider)
		assert.is_nil(provider:get_role("TEST", "SX"))
	end)

	it("acls:get_role (privilege extension, set/get missing privilege)", function()
		local provider = acls:get_provider("$name")
		assert.not_nil(provider)
		acls:set_role("TEST", "$interact", "read")
		assert.not_equals(acls:get_provider("name"), provider)
		assert.is_false(provider:get_role("TEST", "SX"))
	end)

	it("acls:get_role (privilege extension, set/get valid privilege)", function()
		local provider = acls:get_provider("$name")
		assert.not_nil(provider)
		acls:set_role("TEST", "$shout", "read")
		assert.not_equals(acls:get_provider("name"), provider)
		assert.equals("read", provider:get_role("TEST", "SX"))
	end)

	it("acls:get_role (privilege extension, non player)", function()
		local provider = acls:get_provider("$name")
		assert.not_nil(provider)
		assert.not_equals(acls:get_provider("name"), provider)
		assert.is_nil(provider:get_role("TEST", "?"))
	end)

	it("acls:get_role (unknown/missing extension)", function()
		local provider = acls:get_provider("%name")
		assert.is_nil(provider)
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
		assert.equals("manager", acls:get_role("TEST", "SX"))
		acls:set_role("TEST", "SX", "deny")
		assert.equals("deny", acls:get_role("TEST", "SX"))
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

describe("ACL/acls caching", function()

	local M = function(s) return require("luassert.match").matches(s) end

	local acls, SX

	before_each(function()
		_G.beerchat = { channels = { TEST = {} } }
		acls = sourcefile("plugin/acl/acls")(nil, function() end)
		acls:register_provider("*", dofile("plugin/acl/players.lua"))
		acls:register_provider("$", dofile("plugin/acl/privileges.lua"))
		SX = Player("SX", { shout = 1, fast = 1 })
		mineunit:execute_on_joinplayer(SX)
	end)

	after_each(function()
		mineunit:execute_on_leaveplayer(SX)
		SX = nil
	end)

	local function spy_idp_identities(name)
		local idp = assert(acls:get_provider(name))
		spy.on(idp, "identities")
		return idp
	end

	it("acls:get_role caching not needed for names", function()
		local idp = spy_idp_identities("SX")
		acls:set_role("TEST", "SX", "write")
		acls:get_role("TEST", "SX", "read")
		local role = acls:get_role("TEST", "SX", "read")
		assert.spy(idp.identities).not_called()
		assert.equals("write", role)
	end)

	it("acls:get_role caching is used for fallback roles", function()
		local idp = spy_idp_identities("*")
		acls:set_role("TEST", "*", "write")
		-- First call populates cache, second call uses cache
		local role1 = acls:get_role("TEST", "SX", "read")
		local role2 = acls:get_role("TEST", "SX", "read")
		assert.spy(idp.identities).called(1)
		assert.equals("write", role1)
		assert.equals(role1, role2)
	end)

	it("acls:get_role caching is used for privilege roles", function()
		local idp = spy_idp_identities("$shout")
		acls:set_role("TEST", "$shout", "write")
		-- First call populates cache, second call uses cache
		local role1 = acls:get_role("TEST", "SX", "read")
		local role2 = acls:get_role("TEST", "SX", "read")
		assert.spy(idp.identities).called(1)
		assert.equals("write", role1)
		assert.equals(role1, role2)
	end)

	it("acls:set_role invalidates caching for fallback roles", function()
		local idp = spy_idp_identities("*")
		acls:set_role("TEST", "*", "manager")
		-- acls:set_role clears caches
		local role1 = acls:get_role("TEST", "SX", "read")
		acls:set_role("TEST", "*", "write")
		local role2 = acls:get_role("TEST", "SX", "read")
		assert.spy(idp.identities).called(2)
		assert.equals("manager", role1)
		assert.equals("write", role2)
	end)

	it("acls:set_role invalidates caching for privilege roles", function()
		local idp = spy_idp_identities("$shout")
		acls:set_role("TEST", "$shout", "manager")
		-- acls:set_role clears caches
		local role1 = acls:get_role("TEST", "SX", "read")
		acls:set_role("TEST", "$shout", "write")
		local role2 = acls:get_role("TEST", "SX", "read")
		assert.spy(idp.identities).called(2)
		assert.equals("manager", role1)
		assert.equals("write", role2)
	end)

end)