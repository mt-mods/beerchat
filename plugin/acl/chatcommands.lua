-- ACL chat commands
--

local acls = ...

local fmt_prefix = ""
local fmt_exists = "Role `${role}` already exists for `${target}` on #${channel}."
local fmt_noneed = "Identity `${target}` had no roles on #${channel}."
local invite_sound = "beerchat_chirp" -- Sound when sending / receiving an invite to a channel

local function align(s, w, r)
	s = tostring(s)
	return s .. string.rep(r, w - #s)
end

local function list_acls(channel)
	local roles = acls:get_roles(channel)
	if roles then
		local result = {}
		local c1_length = 8 -- "Identity" header
		local c2_length = 4 -- "Role" header
		if #roles == 1 then
			c1_length = math.max(#roles[1].identity, c1_length)
			c2_length = math.max(#roles[1].role, c2_length)
		else
			table.sort(roles, function(a, b)
				c1_length = math.max(#a.identity, #b.identity, c1_length)
				c2_length = math.max(#a.role, #b.role, c2_length)
				return a.identity ~= "*" and a.identity:lower() < b.identity:lower()
			end)
		end
		c1_length = c1_length + 1 -- Gap between identity and role
		table.insert(result, align("Identity", c1_length, " ") .. "Role")
		table.insert(result, align("", c1_length + c2_length, "-"))
		for _, aclrole in ipairs(roles) do
			table.insert(result, align(aclrole.identity, c1_length, " ") .. aclrole.role)
		end
		return table.concat(result, "\n")
	end
	return "Channel #"..channel.." is not using any access control lists."
end

local channel_acl = {
	params = "<Channel Name> [[-d] <Identity> [Access Role]]",
	description = "Invite player to channel or manage permissions on channel <Channel Name>. Use -d to remove identity"
		.. " from channel. You must be at least channel manager in order to invite others or manage permissions.\n"
		.. "Identity can be a player name or privilege. Privileges must be prefixed with $, for example: $interact.\n"
		.. "Possible access roles are: deny, read, write (default), manager or owner.",
	func = function(name, param)
		if not param or param == "" then
			return false, "ERROR: Invalid arguments. Please supply at least the channel name and the player name.\n"
				.. "Identity can be player name or privilege if prefixed with $, for example: $interact."
				.. "Basic access roles are: deny, read, write (default), manager or owner."
		end

		local data, delete = {}
		do -- parse arguments
			local args, role
			data.channel, args = param:match("#?(%S+)%s*(.*)")
			delete, param = args:match("^(%-d)%s*(.*)$")
			if param then
				data.target, role = param:match("(%S+)%s*(%S*)")
			else
				data.target, role = args:match("(%S+)%s*(%S*)")
			end
			if not delete and role then
				data.role = role ~= "" and role or "write"
			end
		end

		if not data.channel or data.channel == "" then
			return false, "ERROR: Channel name is empty."
		elseif not beerchat.channels[data.channel] then
			return false, "ERROR: Channel #" .. data.channel .. " does not exist."
		elseif not delete and not data.target and not data.role then
			return true, list_acls(data.channel)
		elseif not data.target or data.target == "" then
			return false, "ERROR: Identity not supplied or empty."
		end

		local provider = acls:get_provider(data.target)
		if not provider or not provider:validate(data.target) then
			return false, "ERROR: Invalid identity."
		end

		-- Callbacks to check access and possibly modify original request
		if not beerchat.execute_callbacks('before_invite', name, data) then
			return true -- Assume that callback handler already handled error messages
		end

		-- Exact identity provider role, here we want exact match instead of access control match
		data.old_role = acls:get_idp_role(data.channel, data.target)
		if data.old_role == data.role then
			-- Nothing to do, target already has or does not have requested role
			return true, beerchat.format_string(delete and fmt_noneed or fmt_exists, data)
		end

		if not acls:set_role(data.channel, data.target, data.role) then
			-- Failed setting role for target
			return false, "ERROR: Could not set role `" .. data.role .. "` for " .. data.target
		end

		-- Notifications for invitations / new roles, identity provider decides if message should be sent
		if data.role and not data.old_role then
			local message = provider:get_invite_message(name, data)
			if message and beerchat.allow_private_message(name, data.target) then
				-- To player receiving new role, not for deletions / updates
				beerchat.sound_play(data.target, invite_sound)
				minetest.chat_send_player(data.target,  beerchat.format_message(fmt_prefix .. message, {
					channel = data.channel,
					from_player = name,
					to_player = data.target,
				}))
			end
		end

		-- Feedback to the operator, identity provider decides if message should be sent
		local message = provider:get_feedback_message(name, data)
		if message then
			minetest.chat_send_player(name, beerchat.format_message(fmt_prefix .. message, {
				channel = data.channel,
				from_player = name,
				to_player = data.target,
			}))
		end
	end
}

minetest.register_chatcommand("channel_acl", channel_acl)
minetest.register_chatcommand("ca", channel_acl)
minetest.register_chatcommand("invite_channel", channel_acl)
minetest.register_chatcommand("ic", channel_acl)
