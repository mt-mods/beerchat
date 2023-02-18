--luacheck: no_unused_args
-- ACL extension for privilege based roles
--

local fmt_delete = "ACL entry removed for `${target}` privilege at #${channel}."
local fmt_update = "ACL entry updated for `${target}` privilege from `${old_role}` to `${role}` at #${channel}."
local fmt_create = "ACL entry added for `${target}` privilege with `${role}` access at #${channel}."

local def = {}

function def:identities(name)
	return pairs(minetest.get_player_privs(name))
end

function def:validate(identity)
	if #identity < 2 or identity:sub(1,1) ~= "$" then
		return false
	end
	return minetest.registered_privileges[identity:sub(2)] ~= nil
end

function def:get_invite_message()
	-- noop: do not send invite messages when data.target is privilege instead of player
end

function def:get_feedback_message(from, data)
	if data.role and data.old_role then
		-- Updating role
		return beerchat.format_string(fmt_update, data)
	elseif data.role then
		-- Adding role
		return beerchat.format_string(fmt_create, data)
	elseif data.old_role then
		-- Removing role
		return beerchat.format_string(fmt_delete, data)
	end
	-- No meaningful action
end

return def
