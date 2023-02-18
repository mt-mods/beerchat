local channel_created_string = "|#${channel}| Channel created"
local channel_updated_string = "|#${channel}| Channel updated"
local channel_deleted_string = "|#${channel}| Channel deleted"
local channel_left_string = "|#${channel}| Left channel"
local nochannel_string = "|#${channel}| Channel does not exist, will unregister channel from your list of channels"

local leave_channel_sound = "beerchat_chirp" -- Sound when you leave a channel

local create_channel = {
	params = "<Channel Name>[[,<Password>],<Color>]",
	description = "Create or edit a channel named <Channel Name> with optional <Password> and hexadecimal <Color> "
		.. "starting with # (e.g. #00ff00 for green, defaults to #ffffff). Use commas to separate the arguments, e.g. "
		.. "/cc my-secret-channel,#0000ff for a blue colored my-secret-channel without password",
	func = function(lname, param)
		if not param or param == "" then
			return false, "ERROR: Invalid number of arguments. Please supply the channel name as a minimum."
		end

		local str = param:gsub("^#",""):split(",")
		if #str > 3 then
			return false, "ERROR: Invalid number of arguments. 4 parameters passed, "
				.. "maximum of 3 allowed: <Channel Name>,<Password>,<Color>"
		end

		local lchannel_name = (str[1] or ""):trim():gsub("%s", "-")
		if lchannel_name == "" then
			return false, "ERROR: You must supply a channel name"
		elseif lchannel_name == beerchat.main_channel_name then
			return false, "ERROR: You cannot use channel name \"" .. beerchat.main_channel_name .. "\""
		end

		local msg = channel_created_string
		if beerchat.channels[lchannel_name] then
			local cowner = beerchat.channels[lchannel_name].owner
			if not cowner or cowner == "" or cowner ~= lname then
				return false, "ERROR: Channel " .. lchannel_name .. " already exists, owned by player " .. cowner
			end
			msg = channel_updated_string
		end

		local arg2 = str[2]
		local lcolor = beerchat.default_channel_color
		local lpassword = ""

		if arg2 then
			if string.sub(arg2, 1, 1) ~= "#" then
				lpassword = arg2
			else
				lcolor = string.lower(str[2])
			end
		end

		if #str == 3 then
			lcolor = string.lower(str[3])
		end

		beerchat.channels[lchannel_name] = { owner = lname, name = lchannel_name, password = lpassword, color = lcolor }
		beerchat.mod_storage:set_string("channels", minetest.write_json(beerchat.channels))

		beerchat.add_player_channel(lname, lchannel_name, "owner")
		beerchat.sound_play(lname, beerchat.channel_management_sound)
		minetest.chat_send_player(lname, beerchat.format_message(msg, { channel = lchannel_name }))
		return true
	end
}

local delete_channel = {
	params = "<Channel Name>",
	description = "Delete channel named <Channel Name>. You must be the owner of the "
		.. "channel to be allowed to delete the channel",
	func = function(name, param)
		if not param or param == "" then
			return false, "ERROR: Invalid number of arguments. Please supply the "
				.. "channel name"
		elseif param == beerchat.main_channel_name then
			return false, "ERROR: Cannot delete the main channel!"
		elseif not beerchat.channels[param] then
			return false, "ERROR: Channel " .. param .. " does not exist"
		elseif name ~= beerchat.channels[param].owner and not minetest.check_player_privs(name, beerchat.admin_priv) then
			return false, "ERROR: You are not the owner of channel " .. param
		end

		local delete = { channel = param }
		if not beerchat.execute_callbacks('before_delete_channel', name, delete) then
			return true
		end

		local color = beerchat.channels[delete.channel].color
		beerchat.channels[delete.channel] = nil
		beerchat.mod_storage:set_string("channels", minetest.write_json(beerchat.channels))

		beerchat.remove_player_channel(name, delete.channel)

		beerchat.sound_play(name, beerchat.channel_management_sound)
		minetest.chat_send_player(name, beerchat.format_message(
			channel_deleted_string, { channel = delete.channel, color = color }
		))
		return true
	end
}

local my_channels = {
	params = "<Channel Name optional>",
	description = "List the channels you have joined or are the owner of, "
		.. "or show channel information when passing channel name as argument",
	func = function(name, param)
		if not param or param == "" then
			beerchat.sound_play(name, beerchat.channel_management_sound)
			minetest.chat_send_player(name, dump2(beerchat.playersChannels[name])
				.. '\nYour default channel is: '
				.. (beerchat.currentPlayerChannel[name] or '<none>'))
		else
			if beerchat.playersChannels[name][param] then
				beerchat.sound_play(name, beerchat.channel_management_sound)
				minetest.chat_send_player(name, dump2(beerchat.channels[param]))
			else
				return false, "ERROR: Channel is not in your channel list."
			end
		end
		return true
	end
}

local join_channel = {
	params = "<Channel Name>",
	description = "Join channel named <Channel Name>. After joining you will see messages "
		.. "sent to that channel in addition to the other channels you have joined.",
	func = function(name, channel)
		if not channel or channel == "" then
			return false, "ERROR: Invalid arguments. Please supply the channel name."
		end

		channel = channel:match("^#?(%S+)")
		if not channel or not beerchat.channels[channel] then
			return false, "ERROR: Channel " .. (channel or "<empty>") .. " does not exist."
		elseif beerchat.playersChannels[name] and beerchat.playersChannels[name][channel] then
			return false, "ERROR: You already joined " .. channel .. ", no need to rejoin"
		end

		beerchat.join_channel(name, channel)
	end
}

local leave_channel = {
	params = "<Channel Name>",
	description = "Leave channel named <Channel Name>. When you leave the channel you "
		.. "can no longer send / receive messages from that channel. "
		.. "NOTE: You can also leave the main channel",
	func = function(name, channel)
		if not channel or channel == "" then
			return false, "ERROR: Invalid arguments. Please supply the channel name."
		end

		channel = channel:match("^#?(%S+)")
		if not beerchat.playersChannels[name][channel] then
			return false, "ERROR: You are not member of " .. channel .. ", no need to leave."
		elseif not beerchat.execute_callbacks('before_leave', name, channel) then
			return false
		end

		beerchat.remove_player_channel(name, channel)

		beerchat.sound_play(name, leave_channel_sound)
		if not beerchat.channels[channel] then
			minetest.chat_send_player(name, beerchat.format_message(nochannel_string, { channel = channel }))
		else
			minetest.chat_send_player(name, beerchat.format_message(channel_left_string, { channel = channel }))
		end
		return true
	end
}

minetest.register_chatcommand("cc", create_channel)
minetest.register_chatcommand("create_channel", create_channel)
minetest.register_chatcommand("dc", delete_channel)
minetest.register_chatcommand("delete_channel", delete_channel)

minetest.register_chatcommand("mc", my_channels)
minetest.register_chatcommand("my_channels", my_channels)

minetest.register_chatcommand("jc", join_channel)
minetest.register_chatcommand("join_channel", join_channel)
minetest.register_chatcommand("lc", leave_channel)
minetest.register_chatcommand("leave_channel", leave_channel)
