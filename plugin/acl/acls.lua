-- ACL storage

local acls = {
	rolenum = { deny = 0, owner = 1, manager = 2, write = 3, read = 4 },
	data = {},
	idp = {},
}

acls.maxrolenum = (function()
	local count = 0
	for _ in pairs(acls.rolenum) do count = count + 1 end
	return count
end)()

local function is_valid_player_name(name)
	return name:find("[^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789%-_]") == nil
end

local function is_valid_provider_name(name)
	-- Valid provider name should have characters that wont appear in player name
	return name:find("^[^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789%-_]") ~= nil
end

-- rtdef_* are identity provider methods and defined here to avoid shadowing or renaming `self`
local function idp_get_role_default(self, channel, name)
	local cache = self.cache
	if cache[channel] and cache[channel][name] ~= nil then
		return cache[channel][name]
	elseif not acls.data[channel] then
		return
	end

	local num = acls.maxrolenum + 1
	cache[channel] = { [name] = false }
	for identity in self:identities(name) do
		local current = acls.data[channel][self:get_id(identity)]
		if current and acls.rolenum[current] < num then
			cache[channel][name] = current
			num = acls.rolenum[current]
			if num <= 0 then
				break
			end
		end
	end
	return cache[channel][name]
end

local function idp_get_id_default(self, name)
	return self.roletype .. name
end

function acls:register_provider(roletype, def)
	-- Raise error if trying to register invalid provider
	assert(is_valid_provider_name(roletype), "acls:register_provider: invalid roletype '"..tostring(roletype).."'.")
	assert(type(def.validate) == "function", "acls:register_provider: provider must have :validate(identity) method.")
	def.cache = {}
	def.roletype = roletype
	def.get_role = def.get_role or idp_get_role_default
	def.get_id = def.get_id or idp_get_id_default
	self.idp[roletype] = def
end

function acls:get_provider(name)
	if is_valid_provider_name(name) then
		-- Return nil if named provider does not exist
		return self.idp[name:sub(1,1)]
	end
	-- Default provider handles player names
	return self.idp["*"]
end

function acls:check_access(channel, name, minimum, default)
	local role = self:get_role(channel, name, default)
	if role == "deny" or (not role and minimum) then
		return false, "ERROR: You do not have " .. (minimum and minimum or "any") .. " access to #" .. channel .. "."
	elseif minimum then
		if (self.rolenum[minimum] or 0) < self.rolenum[role] then
			return false, "ERROR: You do not have " .. minimum .. " access to #" .. channel .. "."
		end
	end
	-- No role and no minimum will fall through intentionally.
end

-- Get channel role for actual permissions
function acls:get_role(channel, name, default)
	if beerchat.channels[channel] and beerchat.channels[channel].owner == name then
		return "owner"
	end
	local acl = self.data[channel]
	if acl then
		-- First check for name based roles and fallback role if explicitly asking for it
		if name == "*" or acl[name] then
			return acl[name]
		end
		-- Check for roles defined by identity providers if name is valid player name
		if is_valid_player_name(name) then
			for _, provider in pairs(self.idp) do
				local role = provider:get_role(channel, name)
				if role then
					return role
				end
			end
		end
		-- Check for and return wildcard role if configured
		if acl["*"] then
			return acl["*"]
		end
	end
	-- Return default value if any given, nil otherwise
	return default
end

-- Get exact channel role without fallback or secondary roles
function acls:get_idp_role(channel, name)
	if beerchat.channels[channel] and beerchat.channels[channel].owner == name then
		return "owner"
	elseif self.data[channel] then
		return self.data[channel][name]
	end
end

function acls:set_role(channel, name, role)
	if role == nil or self.rolenum[role] then
		self.data[channel] = self.data[channel] or {}
		if self.data[channel][name] ~= role then
			-- Clear caches for role type
			local provider = self:get_provider(name)
			if provider then
				provider.cache[channel] = nil
			end
			-- Set role
			self.data[channel][name] = role
			-- Trigger storage
			self:write_storage()
		end
		return true
	end
	return false
end

function acls:get_roles(channel)
	local acl = self.data[channel]
	if acl then
		local results = {}
		for identity, role in pairs(acl) do
			table.insert(results, {
				identity = identity,
				role = role,
			})
		end
		return results
	end
end

return function(data, write_fn)
	acls.data = data or acls.data
	function acls:write_storage()
		if self.write_pending then
			self.write_pending:cancel()
		end
		self.write_pending = minetest.after(60, function()
			self.write_pending = nil
			write_fn(acls.data)
		end)
	end
	return acls
end
