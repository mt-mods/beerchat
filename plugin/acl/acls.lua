-- ACL storage

local acls = {
	rolenum = { deny = 0, owner = 1, manager = 2, write = 3, read = 4 },
	dirty = false,
	data = {},
	roletype = {}, -- Definitions and data for special role types, privilege roles for example
}

acls.maxrolenum = (function()
	local count = 0
	for _ in pairs(acls.rolenum) do count = count + 1 end
	return count
end)()

function acls:register_provider(roletype, def)
	self.roletype[roletype] = table.copy(def)
	self.roletype[roletype].cache = {}
end

function acls:check_access(channel, name, minimum, ...)
	local role = self:get_role(channel, name, ...)
	if role == "deny" or (not role and minimum) then
		return false, "ERROR: You do not have " .. (minimum and minimum or "any") .. " access to #" .. channel .. "."
	elseif minimum then
		if (self.rolenum[minimum] or 0) < self.rolenum[role] then
			return false, "ERROR: You do not have " .. minimum .. " access to #" .. channel .. "."
		end
	end
	-- No role and no minimum will fall through intentionally.
end

function acls:get_special_role(channel, name, roletype)
	local def = assert(self.roletype[roletype], "Invalid special ACL role type `"..roletype.."`.")

	local rolecache = def.cache[channel]
	if rolecache and rolecache[name] ~= nil then
		return rolecache[name]
	elseif not self.data[channel] then
		return
	end

	local num = self.maxrolenum + 1
	def.cache[channel] = { [name] = false }
	for identity in def.identities(name) do
		local current = self.data[channel][roletype..identity]
		if current and self.rolenum[current] < num then
			def.cache[channel][name] = current
			num = self.rolenum[current]
			if num <= 0 then
				break
			end
		end
	end
	return def.cache[channel][name]
end

function acls:get_role(channel, name, ...)
	if beerchat.channels[channel] and beerchat.channels[channel].owner == name then
		return "owner"
	end
	local acl = self.data[channel]
	if acl then
		-- First check for name based roles
		if acl[name] then
			return acl[name]
		end
		-- Second check for privilege roles
		local role = self:get_special_role(channel, name, '$')
		if role then
			return role
		elseif acl["*"] then
			return acl["*"]
		end
	end
	-- Return default value if any given, nil otherwise
	return ({...})[1]
end

function acls:set_role(channel, name, role)
	self.data[channel] = self.data[channel] or {}
	if self.data[channel][name] ~= role then
		local prefix = name:sub(1,1)
		if self.roletype[prefix] then
			self.roletype[prefix].cache[channel] = nil
		end
		self.data[channel][name] = role
		self.dirty = true
	end
end

-- Compatibility for privilege roles
-- TODO / PoC: Move this privilege stuff to separate file.
acls:register_provider("$", {
	identities = function(name)
		return pairs(minetest.get_player_privs(name))
	end
})
function acls:get_privilege_role(channel, name)
	return self:get_special_role(channel, name, "$")
end

return function(data, write_fn)
	acls.data = data or acls.data
	acls.write_storage = function(self)
		if self.dirty then
			write_fn(self.data)
			self.dirty = false
		end
	end
	return acls
end
