-- ACL storage

local acls = {
	rolenum = { deny = 0, owner = 1, manager = 2, write = 3, read = 4 },
	dirty = false,
	data = {},
	privilege_cache = {}
}

acls.maxrolenum = (function()
	local count = 0
	for _ in pairs(acls.rolenum) do count = count + 1 end
	return count
end)()

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

function acls:get_privilege_role(channel, name)
	if self.privilege_cache[channel] and self.privilege_cache[channel][name] ~= nil then
		return self.privilege_cache[channel][name]
	elseif not self.data[channel] then
		return
	end
	local privs = minetest.get_player_privs(name)
	local num = self.maxrolenum + 1
	self.privilege_cache[channel] = { [name] = false }
	for priv in pairs(privs) do
		local current = self.data[channel]["$"..priv]
		if current and self.rolenum[current] < num then
			self.privilege_cache[channel][name] = current
			num = self.rolenum[current]
			if num <= 0 then
				break
			end
		end
	end
	return self.privilege_cache[channel][name]
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
		local role = self:get_privilege_role(channel, name)
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
		if name:sub(1,1) == "$" then
			self.privilege_cache[channel] = nil
		end
		self.data[channel][name] = role
		self.dirty = true
	end
end

local write_storage

function acls:write_storage()
	if self.dirty then
		write_storage(self.data)
		self.dirty = false
	end
end

return function(data, write_fn)
	acls.data = data or acls.data
	write_storage = write_fn
	return acls
end
