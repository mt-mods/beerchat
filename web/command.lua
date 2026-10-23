-- commandname -> func() string
local commands = {}

function beerchat.register_relaycommand(name, fn)
	assert(
		type(name) == "string",
		"beerchat.register_relaycommand received type " .. type(name) .. " instead of string in first argument"
	)
	assert(
		type(fn) == "function",
		"beerchat.register_relaycommand received type " .. type(name) .. " instead of function in second argument"
	)
	commands[name] = fn
end

function beerchat.get_relaycommand(name)
	return commands[name]
end

function beerchat.get_available_relaycommands()
	local names = {}
	for name, _ in pairs(commands) do
		table.insert(names, name)
	end

	return names
end
