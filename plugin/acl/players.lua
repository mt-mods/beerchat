--luacheck: no_unused_args
-- ACL extension for player based roles
--

local fmt_invited = "${from_player} invited you to join the channel #${channel}."
local fmt_invite = "Sent invite for ${target} to join #${channel} with `${role}` role."
local fmt_denied = "Denied channel access for ${target} at #${channel}."
local fmt_create = "Added default ACL role `${role}` for #${channel}."
local fmt_update = "Updated ACL entry for ${target} from `${old_role}` to `${role}` at #${channel}."
local fmt_delete = "Removed ACL entry for ${target} from channel #${channel}."

local def = {}

-- Sequential iterator without index
local function values(t)
	local index = 0
	return function()
		index = index + 1
		return t[index]
	end
end

function def:identities(name)
	return values({self:get_id(name)})
end

function def:validate(identity)
	return identity == "*" or minetest.get_auth_handler().get_auth(identity)
end

function def:get_invite_message(from, data)
	if data.target ~= "*" and data.role ~= "deny" then
		return beerchat.format_string(fmt_invited, data)
	end
end

function def:get_feedback_message(from, data)
	if data.role and data.old_role then
		-- Updating role
		return beerchat.format_string(fmt_update, data)
	elseif data.role and data.target == "*" then
		-- Adding default role
		return beerchat.format_string(fmt_create, data)
	elseif data.role then
		-- Adding role
		return beerchat.format_string(data.role == "deny" and fmt_denied or fmt_invite, data)
	elseif data.old_role then
		-- Removing role
		return beerchat.format_string(fmt_delete, data)
	end
	-- No meaningful action
end

return def
