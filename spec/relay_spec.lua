require("mineunit")

mineunit("core")
mineunit("player")
mineunit("server")
mineunit("http")

-- mineunit doesn't have a stub for register_on_auth_fail, so add one
minetest.register_on_auth_fail = function(...) end

sourcefile("init")

describe("Relay", function()

  it("lists available commands", function()
    local fn = beerchat.get_relaycommand("help")
    local out = fn()

    assert.has.match("Available commands:.*help", out)
  end)

end)
