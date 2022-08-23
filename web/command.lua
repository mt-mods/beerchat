
-- commandname -> func() string
local commands = {}

function beerchat.register_relaycommand(name, fn)
    assert(type(name) == "string")
    assert(type(fn) == "function")
    commands[name] = fn
end

function beerchat.get_relaycommand(name)
    return commands[name]
end
