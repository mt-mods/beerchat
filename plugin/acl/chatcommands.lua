-- ACL chat commands
--

local acls = ...

local fmt_deleted = "|#${channel}| Removed ACL entry ${to_player} from channel #${channel}."
local fmt_privilege = "|#${channel}| ACL updated for ${from_player}."
	.. " Player role was `${old_role}` and has now been updated to `${role}`."
local fmt_management = "|#${channel}| ACL updated for ${from_player}."
	.. " Player role was `${old_role}` and has now been updated to `${role}`."
local fmt_invitation = "|#${channel}| ${from_player} invited you to join the channel #${channel}."
	.. " Do /jc ${channel} after which you can send messages to the channel via #${channel} message."
local fmt_invited = "|#${channel}| Invite sent to ${to_player} with `${role}` access role."
local invite_sound = "beerchat_chirp" -- Sound when sending / receiving an invite to a channel

local invite_channel = {
	params = "<Channel Name> [-d] <Identity> [Access Role]",
	description = "Invite player to channel or manage permissions on channel <Channel Name>. Use -d to remove identity"
		.. " from channel. You must be at least channel manager in order to invite others or manage permissions.\n"
		.. "Identity can be player name or privilege. Privileges must be prefixed with $, for example: $interact.\n"
		.. "Possible access roles are: deny, read, write (default), manager or owner.",
	func = function(name, param)
		if not param or param == "" then
			return false, "ERROR: Invalid arguments. Please supply at least the channel name and the player name.\n"
				.. "Identity can be player name or privilege if prefixed with $, for example: $interact."
				.. "Basic access roles are: deny, read, write (default), manager or owner."
		end

		local channel, delete, recipient, role
		do -- parse arguments
			local args
			channel, args = param:match("#?(%S+)%s+(.+)")
			delete, param = args:match("^(%-d)%s+(.+)$")
			if param then
				recipient, role = param:match("(%S+)%s*(%S*)")
			else
				recipient, role = args:match("(%S+)%s*(%S*)")
			end
		end

		if not channel or channel == "" then
			return false, "ERROR: Channel name is empty."
		elseif not recipient or recipient == "" then
			return false, "ERROR: Player name not supplied or empty."
		elseif not beerchat.channels[channel] then
			return false, "ERROR: Channel #" .. channel .. " does not exist."
		end

		-- Use callbacks to check access
		role = not delete and (role ~= "" and role or "write") or nil
		local data = { target = recipient, channel = channel, role = role }
		if not beerchat.execute_callbacks('before_invite', name, data) then
			return true -- Assume that callback handler already handled error messages
		end

		local old_role = acls:get_role(data.channel, data.target, nil)
		acls:set_role(data.channel, data.target, data.role)

		local format_string
		if data.target:sub(1,1) == "$" then
			format_string = delete and fmt_deleted or fmt_privilege
		else
			format_string = delete and fmt_deleted or (old_role and fmt_management or fmt_invited)
			if not delete and not old_role and beerchat.allow_private_message(name, data.target) then
				-- Message to player who was invited to channel
				beerchat.sound_play(data.target, invite_sound)
				minetest.chat_send_player(data.target, beerchat.format_message(fmt_invitation, {
					channel = data.channel,
					from_player = name
				}))
			end
		end
		-- Feedback to player who ran command and updated access for other player
		beerchat.sound_play(name, invite_sound)
		local preformatted = beerchat.format_string(format_string, { old_role = old_role, role = data.role })
		minetest.chat_send_player(name, beerchat.format_message(preformatted, {
			channel = data.channel,
			from_player = name,
			to_player = data.target,
		}))
	end
}

minetest.register_chatcommand("ic", invite_channel)
minetest.register_chatcommand("invite_channel", invite_channel)
minetest.register_chatcommand("channel_acl", invite_channel)
