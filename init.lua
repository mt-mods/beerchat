local mod_storage = minetest.get_mod_storage()
local channels = {}

--
-- Mod settings -- Change these to your liking
--
local main_channel_name = "main"			-- The main channel is the one you send messages to when no channel is specified
local main_channel_owner = "Beerholder"		-- The owner of the main channel, usually ADMIN
local main_channel_color = "#ffffff"		-- The color in hex of the main channel

local default_channel_color = "#ffffff"		-- The default color of channels when no color is specified

local enable_sounds = true									-- Global flag to enable/ disable sounds
local channel_management_sound = "beerchat_chirp"		-- General sound when managing channels like /cc, /dc etc
local join_channel_sound = "beerchat_chirp"			-- Sound when you join a channel
local leave_channel_sound = "beerchat_chirp"			-- Sound when you leave a channel
local channel_invite_sound = "beerchat_chirp"			-- Sound when sending/ receiving an invite to a channel
local channel_message_sound = "beerchat_chime"		-- Sound when a message is sent to a channel
local private_message_sound = "beerchat_chime"		-- Sound when you receive a private message
local self_message_sound = "beerchat_utter"			-- Sound when you send a private message to yourself

local whisper_default_range = 32		-- Default whisper range when whispering without specifying a radius
local whisper_max_range = 200			-- Maximum whisper range that can be specified when whispering
local whisper_color = "#aaaaaa"			-- Whisper color override

-- Message string formats -- Change these if you would like different formatting
--
-- These can be changed to show "~~~#mychannel~~~ <player01> message" instead of "|#mychannel| or any
-- other format you like such as removing the channel name from the main channel, putting channel or
-- player names at the end of the chat message, etc.
--
-- The following parameters are available and can be specified :
-- ${channel_name} name of the channel
-- ${channel_owner} owner of the channel
-- ${channel_password} password to use when joining the channel, used e.g. for invites
-- ${from_player} the player that is sending the message
-- ${to_player} player to which the message is sent, will contain multiple player names e.g. when sending a PM to multiple players
-- ${message} the actual message that is to be sent
-- ${time} the current time in 24 hour format, as returned from os.date("%X")
--
local channel_invitation_string = "|#${channel_name}| Channel invite from (${from_player}), to join the channel, do /jc ${channel_name},${channel_password} after which you can send messages to the channel via #${channel_name}: message"
local channel_invited_string = "|#${channel_name}| Invite sent to ${to_player}"
local channel_created_string = "|#${channel_name}| Channel created"
local channel_deleted_string = "|#${channel_name}| Channel deleted"
local channel_joined_string = "|#${channel_name}| Joined channel"
local channel_left_string = "|#${channel_name}| Left channel"
local channel_already_deleted_string = "|#${channel_name}| Channel seems to have already been deleted, will unregister channel from your list of channels"
local private_message_string = "[PM] from (${from_player}) ${message}"
local self_message_string = "(${from_player} utters to him/ herself) ${message}"
local private_message_sent_string = "[PM] sent to @(${to_player}) ${message}"
local me_message_string = "|#${channel_name}| * ${from_player} ${message}"
local channel_message_string = "|#${channel_name}| <${from_player}> ${message}"
local main_channel_message_string = "|#${channel_name}| <${from_player}> ${message}"
local whisper_string = "|#${channel_name}| <${from_player}> whispers: ${message}"

function format_message(s, tab)
	local owner
	local password
	local color = default_channel_color

	if tab.channel_name and channels[tab.channel_name] then
		owner = channels[tab.channel_name].owner
		password = channels[tab.channel_name].password
		color = channels[tab.channel_name].color
	end

	if tab.color then
		color = tab.color
	end

	local params = {
		channel_name = tab.channel_name,
		channel_owner = owner,
		channel_password = password,
		from_player = tab.from_player,
		to_player = tab.to_player,
		message = tab.message,
		time = os.date("%X")
	}
	return string.char(0x1b).."(c@"..color..")"..format_string(s, params)
end

function format_string(s, tab)
  return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

if mod_storage:get_string("channels") == "" then
	minetest.log("action", "[beerchat] One off initializing mod storage")
	channels[main_channel_name] = { owner = main_channel_owner, color = main_channel_color }
	mod_storage:set_string("channels", minetest.write_json(channels))
end

channels = minetest.parse_json(mod_storage:get_string("channels"))

playersChannels = {}
local currentPlayerChannel = {}

minetest.register_on_joinplayer(function(player)
	local str = player:get_attribute("beerchat:channels")
	if str and str ~= "" then
		playersChannels[player:get_player_name()] = {}
		playersChannels[player:get_player_name()] = minetest.parse_json(str)
	else
		playersChannels[player:get_player_name()] = {}
		playersChannels[player:get_player_name()][main_channel_name] = "joined"
		player:set_attribute("beerchat:channels", minetest.write_json(playersChannels[player:get_player_name()]))
	end

	local current_channel = player:get_attribute("beerchat:current_channel")
	if current_channel and current_channel ~= "" then
		currentPlayerChannel[player:get_player_name()] = current_channel
	else
		currentPlayerChannel[player:get_player_name()] = main_channel_name
	end

end)

minetest.register_on_leaveplayer(function(player)
	playersChannels[player:get_player_name()] = nil
	atchat_lastrecv[player:get_player_name()] = nil
	currentPlayerChannel[player:get_player_name()] = nil
end)

local create_channel = {
	params = "<Channel Name>,<Password (optional)>,<Color (optional, default is #ffffff)>",
	description = "Create a channel named <Channel Name> with optional <Password> and hexadecimal <Color> "..
				  "starting with # (e.g. #00ff00 for green). Use comma's to separate the arguments, e.g. "..
				  "/cc my secret channel,#0000ff for a blue colored my secret channel without password",
	func = function(lname, param)
		local lowner = lname

		if not param or param == "" then
			return false, "ERROR: Invalid number of arguments. Please supply the channel name as a minimum"
		end

		local str = string.split(param, ",")
		if #str > 3 then
			return false, "ERROR: Invalid number of arguments. 4 parameters passed, maximum of 3 allowed: <Channel Name>,<Password>,<Color>"
		end

		local lchannel_name = string.trim(str[1])
		if lchannel_name == "" then
			return false, "ERROR: You must supply a channel name"
		end

		if lchannel_name == main_channel_name then
			return false, "ERROR: You cannot use channel name \""..main_channel_name.."\""
		end

		if channels[lchannel_name] then
			return false, "ERROR: Channel "..lchannel_name.." already exists, owned by player "..channels[lchannel_name].owner
		end

		local arg2 = str[2]
		local lcolor = default_channel_color
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

		channels[lchannel_name] = { owner = lowner, name = lchannel_name, password = lpassword, color = lcolor }
		mod_storage:set_string("channels", minetest.write_json(channels))

		playersChannels[lowner][lchannel_name] = "owner"
		minetest.get_player_by_name(lowner):set_attribute("beerchat:channels", minetest.write_json(playersChannels[lowner]))
		if enable_sounds then
			minetest.sound_play(channel_management_sound, { to_player = lowner, gain = 1.0 } )
		end
		minetest.chat_send_player(lowner, format_message(channel_created_string, { channel_name = lchannel_name }))

		return true
	end
}

local delete_channel = {
	params = "<Channel Name>",
	description = "Delete channel named <Channel Name>. You must be the owner of the channel or you are not allowed to delete the channel",
	func = function(name, param)
		local owner = name

		if not param or param == "" then
			return false, "ERROR: Invalid number of arguments. Please supply the channel name"
		end

		if param == main_channel_name then
			return false, "ERROR: Cannot delete the main channel!!"
		end

		if not channels[param] then
			return false, "ERROR: Channel "..param.." does not exist"
		end

		if name ~= channels[param].owner then
			return false, "ERROR: You are not the owner of channel "..param
		end

		local color = channels[param].color
		channels[param] = nil
		mod_storage:set_string("channels", minetest.write_json(channels))

		playersChannels[name][param] = nil
		minetest.get_player_by_name(name):set_attribute("beerchat:channels", minetest.write_json(playersChannels[name]))

		if enable_sounds then
			minetest.sound_play(channel_management_sound, { to_player = name, gain = 1.0 } )
		end

		minetest.chat_send_player(name, format_message(channel_deleted_string, { channel_name = param, color = color }))

		return true

	end
}

local my_channels = {
	params = "<Channel Name optional>",
	description = "List the channels you have joined or are the owner of, or show channel information when passing channel name as argument",
	func = function(name, param)
		if not param or param == "" then
			if enable_sounds then
				minetest.sound_play(channel_management_sound, { to_player = name, gain = 1.0 } )
			end
			minetest.chat_send_player(name, dump2(playersChannels[name]))
		else
			if playersChannels[name][param] then
				if enable_sounds then
					minetest.sound_play(channel_management_sound, { to_player = name, gain = 1.0 } )
				end
				minetest.chat_send_player(name, dump2(channels[param]))
			else
				minetest.chat_send_player(name, "ERROR: Channel not in your channel list")
				return false
			end
		end
		return true
	end
}

local join_channel = {
	params = "<Channel Name>,<Password (only mandatory if channel was created using a password)>",
	description = "Join channel named <Channel Name>. After joining you will see messages sent to that channel (in addition to the other channels you have joined)",
	func = function(name, param)
		if not param or param == "" then
			return false, "ERROR: Invalid number of arguments. Please supply the channel name as a minimum"
		end

		local str = string.split(param, ",")
		local channel_name = str[1]

		if not channels[channel_name] then
			return false, "ERROR: Channel "..channel_name.." does not exist"
		end

		if playersChannels[name][channel_name] then
			return false, "ERROR: You already joined "..channel_name..", no need to rejoin"
		end

		if channels[channel_name].password and channels[channel_name].password ~= "" then
			if #str == 1 then
				return false, "ERROR: This channel requires that you supply a password. Supply it in the following format: /jc my channel,password01"
			end
			if str[2] ~= channels[channel_name].password then
				return false, "ERROR: Invalid password"
			end
		end

		playersChannels[name][channel_name] = "joined"
		minetest.get_player_by_name(name):set_attribute("beerchat:channels", minetest.write_json(playersChannels[name]))
		if enable_sounds then
			minetest.sound_play(join_channel_sound, { to_player = name, gain = 1.0 } )
		end
		minetest.chat_send_player(name, format_message(channel_joined_string, { channel_name = channel_name }))

		return true

	end
}

local leave_channel = {
	params = "<Channel Name>",
	description = "Leave channel named <Channel Name>. When you leave the channel you can no longer send/ receive messages from that channel. NOTE: You can also leave the main channel",
	func = function(name, param)
		if not param or param == "" then
			return false, "ERROR: Invalid number of arguments. Please supply the channel name"
		end

		local channel_name = param

		if not playersChannels[name][channel_name] then
			return false, "ERROR: You are not member of "..channel_name..", no need to leave"
		end

		playersChannels[name][channel_name] = nil
		minetest.get_player_by_name(name):set_attribute("beerchat:channels", minetest.write_json(playersChannels[name]))

		if enable_sounds then
			minetest.sound_play(leave_channel_sound, { to_player = name, gain = 1.0 } )
		end
		if not channels[channel_name] then
			minetest.chat_send_player(name, format_message(channel_already_deleted_string, { channel_name = channel_name }))
		else
			minetest.chat_send_player(name, format_message(channel_left_string, { channel_name = channel_name }))
		end

		return true

	end
}

local invite_channel = {
	params = "<Channel Name>,<Player Name>",
	description = "Invite player named <Player Name> to channel named <Channel Name>. You must be the owner of the channel in order to do invites",
	func = function(name, param)
		local owner = name

		if not param or param == "" then
			return false, "ERROR: Invalid number of arguments. Please supply the channel name and the player name"
		end

		local channel_name, player_name = string.match(param, "(.*),(.*)")

		if not channel_name or channel_name == "" then
			return false, "ERROR: Channel name is empty"
		end

		if not player_name or player_name == "" then
			return false, "ERROR: Player name not supplied or empty"
		end

		if not channels[channel_name] then
			return false, "ERROR: Channel "..channel_name.." does not exist"
		end

		if name ~= channels[channel_name].owner then
			return false, "ERROR: You are not the owner of channel "..param
		end

		if not minetest.get_player_by_name(player_name) then
			return false, "ERROR: "..player_name.." does not exist or is not online"
		else
			if not minetest.get_player_by_name(player_name):get_attribute("beerchat:muted:"..name) then
				if enable_sounds then
					minetest.sound_play(channel_invite_sound, { to_player = player_name, gain = 1.0 } )
				end
				-- Sending the message
				minetest.chat_send_player(player_name, format_message(channel_invitation_string, { channel_name = channel_name, from_player = name }))
			end
			if enable_sounds then
				minetest.sound_play(channel_invite_sound, { to_player = name, gain = 1.0 } )
			end
			minetest.chat_send_player(name, format_message(channel_invited_string, { channel_name = channel_name, to_player = player_name }))
		end

		return true
	end
}

local mute_player = {
	params = "<Player Name>",
	description = "Mute a player. After muting a player, you will no longer see chat messages of this user, regardless of what channel his user sends messages to",
	func = function(name, param)
		if not param or param == "" then
			return false, "ERROR: Invalid number of arguments. Please supply the name of the user to mute"
		end

		minetest.get_player_by_name(name):set_attribute("beerchat:muted:"..param, "true")
		minetest.chat_send_player(name, "Muted player "..param)

		return true

	end
}

local unmute_player = {
	params = "<Player Name>",
	description = "Unmute a player. After unmuting a player, you will again see chat messages of this user",
	func = function(name, param)
		if not param or param == "" then
			return false, "ERROR: Invalid number of arguments. Please supply the name of the user to mute"
		end

		minetest.get_player_by_name(name):set_attribute("beerchat:muted:"..param, nil)
		minetest.chat_send_player(name, "Unmuted player "..param)

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
minetest.register_chatcommand("ic", invite_channel)
minetest.register_chatcommand("invite_channel", invite_channel)

minetest.register_chatcommand("mute", mute_player)
minetest.register_chatcommand("ignore", mute_player)
minetest.register_chatcommand("unmute", unmute_player)
minetest.register_chatcommand("unignore", unmute_player)

-- @ chat a.k.a. at chat/ PM chat code, to PM players using @player1 only you can read this player1!!
atchat_lastrecv = {}

minetest.register_on_chat_message(function(name, message)
	local players, msg = string.match(message, "^@([^%s:]*)[%s:](.*)")
	if players and msg then
		if msg == "" then
			minetest.chat_send_player(name, "Please enter the private message you would like to send")
		else
			if players == "" then--reply
				-- We need to get the target
				players = atchat_lastrecv[name]
			end
			if players and players ~= "" then
				local atleastonesent = false
				local successplayers = ""
				for target in string.gmatch(","..players..",", ",([^,]+),") do
					-- Checking if the target exists
					if not minetest.get_player_by_name(target) then
						minetest.chat_send_player(name, ""..target.." is not online")
					else
						if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
							if target ~= name then
								-- Sending the message
								minetest.chat_send_player(target, format_message(private_message_string, { from_player = name, message = msg }))
								if enable_sounds then
									minetest.sound_play(private_message_sound, { to_player = target, gain = 1.0 } )
								end
							else
								minetest.chat_send_player(target, format_message(self_message_string, { from_player = name, message = msg }))
								if enable_sounds then
									minetest.sound_play(self_message_sound, { to_player = target, gain = 1.0 } )
								end
							end
						end
						atleastonesent = true
						successplayers = successplayers..target..","
					end
				end
				-- Register the chat in the target persons last spoken to table
				atchat_lastrecv[name] = players
				if atleastonesent then
					successplayers = successplayers:sub(1, -2)
					if (successplayers ~= name) then
						minetest.chat_send_player(name, format_message(private_message_sent_string, { to_player = successplayers, message = msg }))
					end
				end
			else
				minetest.chat_send_player(name, "You have not sent private messages to anyone yet, please specify player names to send message to")
			end
		end
		return true
	end
end)

local msg_override = {
	params = "<Player Name> <Message>",
	description = "Send private message to player, for compatibility with the old chat command but with new style chat muting support "..
				  "(players will not receive your message if they muted you) and multiple (comma separated) player support",
	func = function(name, param)
		local players, msg = string.match(param, "^(.-) (.*)")
		if players and msg then
			if players == "" then
				minetest.chat_send_player(name, "ERROR: Please enter the private message you would like to send")
				return false
			elseif msg == "" then
				minetest.chat_send_player(name, "ERROR: Please enter the private message you would like to send")
				return false
			else
				if players and players ~= "" then
					local atleastonesent = false
					local successplayers = ""
					for target in string.gmatch(","..players..",", ",([^,]+),") do
						-- Checking if the target exists
						if not minetest.get_player_by_name(target) then
							minetest.chat_send_player(name, ""..target.." is not online")
						else
							if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
								if target ~= name then
									-- Sending the message
									minetest.chat_send_player(target, format_message(private_message_string, { from_player = name, message = msg }))
									if enable_sounds then
										minetest.sound_play(private_message_sound, { to_player = target, gain = 1.0 } )
									end
								else
									minetest.chat_send_player(target, format_message(self_message_string, { from_player = name, message = msg }))
									if enable_sounds then
										minetest.sound_play(self_message_sound, { to_player = target, gain = 1.0 } )
									end
								end
							end
							atleastonesent = true
							successplayers = successplayers..target..","
						end
					end
					-- Register the chat in the target persons last spoken to table
					atchat_lastrecv[name] = players
					if atleastonesent then
						successplayers = successplayers:sub(1, -2)
						if (successplayers ~= name) then
							minetest.chat_send_player(name, format_message(private_message_sent_string, { to_player = successplayers, message = msg }))
						end
					end
				end
			end
			return true
		end
	end
}

minetest.register_chatcommand("msg", msg_override)

local me_override = {
	params = "<Message>",
	description = "Send message in the \"* player message\" format, e.g. /me eats pizza becomes |#"..main_channel_name.."| * Player01 eats pizza",
	func = function(name, param)
		local msg = param
		local channel_name = main_channel_name
		if not channels[channel_name] then
			minetest.chat_send_player(name, "Channel "..channel_name.." does not exist")
		elseif msg == "" then
			minetest.chat_send_player(name, "Please enter the message you would like to send to the channel")
		elseif not playersChannels[name][channel_name] then
			minetest.chat_send_player(name, "You need to join this channel in order to be able to send messages to it")
		else
			for _,player in ipairs(minetest.get_connected_players()) do
				local target = player:get_player_name()
				-- Checking if the target is in this channel
				if playersChannels[target][channel_name] then
					if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
						minetest.chat_send_player(target, format_message(me_message_string, { channel_name = channel_name, from_player = name, message = msg }))
					end
				end
			end
		end
		return true
	end
}

minetest.register_chatcommand("me", me_override)

-- # chat a.k.a. hash chat/ channel chat code, to send messages in chat channels using # e.g. #my channel: hello everyone in my channel!
hashchat_lastrecv = {}

minetest.register_on_chat_message(function(name, message)
	local channel_name, msg = string.match(message, "^#(.-): (.*)")
	if not channels[channel_name] then
		channel_name, msg = string.match(message, "^#(.-) (.*)")
	end
	if channel_name == "" then
		channel_name = hashchat_lastrecv[name]
	end

	if channel_name and msg then
		if not channels[channel_name] then
			minetest.chat_send_player(name, "Channel "..channel_name.." does not exist. Make sure the channel still "..
											"exists and you format its name properly, e.g. #channel message or #my channel: message")
		elseif msg == "" then
			minetest.chat_send_player(name, "Please enter the message you would like to send to the channel")
		elseif not playersChannels[name][channel_name] then
			minetest.chat_send_player(name, "You need to join this channel in order to be able to send messages to it")
		else
			if channel_name == "" then--use last used channel
				-- We need to get the target
				channel_name = hashchat_lastrecv[name]
			end
			if channel_name and channel_name ~= "" then
				for _,player in ipairs(minetest.get_connected_players()) do
					local target = player:get_player_name()
					-- Checking if the target is in this channel
					if playersChannels[target][channel_name] then
						if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
							if channel_name == main_channel_name then
								minetest.chat_send_player(target, format_message(main_channel_message_string, { channel_name = channel_name, from_player = name, message = msg }))
							else
								minetest.chat_send_player(target, format_message(channel_message_string, { channel_name = channel_name, from_player = name, message = msg }))
								if enable_sounds then
									minetest.sound_play(channel_message_sound, { to_player = target, gain = 1.0 } )
								end
							end
						end
					end
				end
				-- Register the chat in the target persons last spoken to table
				hashchat_lastrecv[name] = channel_name
			else
				return false
			end
		end
		return true
	else
		channel_name = string.match(message, "^#(.*)")
		if channel_name then
			if not channels[channel_name] then
				minetest.chat_send_player(name, "Channel "..channel_name.." does not exist")
			elseif not playersChannels[name][channel_name] then
				minetest.chat_send_player(name, "You need to join this channel in order to be able to switch to it")
			else
				currentPlayerChannel[name] = channel_name
				minetest.get_player_by_name(name):set_attribute("beerchat:current_channel", channel_name)
				if channel_name == main_channel_name then
					minetest.chat_send_player(name, "Switched to channel "..channel_name..", messages will now be sent to this channel")
				else
					minetest.chat_send_player(name, "Switched to channel "..channel_name..", messages will now be sent to this channel. To switch back "..
													"to the main channel, type #"..main_channel_name)
				end

				if enable_sounds then
					minetest.sound_play(channel_management_sound, { to_player = name, gain = 1.0 } )
				end
			end
			return true
		end
	end
end)

-- $ chat a.k.a. dollar chat code, to whisper messages in chat to nearby players only using $, optionally supplying a radius e.g. $32 Hello
minetest.register_on_chat_message(function(name, message)
	local dollar, sradius, msg = string.match(message, "^($)(.-) (.*)")
	if dollar == "$" then
		local radius = tonumber(sradius)
		if not radius then
			radius = whisper_default_range
		end

		if radius > whisper_max_range then
			minetest.chat_send_player(name, "You cannot whisper outside of a radius of "..whisper_max_range.." blocks")
		elseif msg == "" then
			minetest.chat_send_player(name, "Please enter the message you would like to whisper to nearby players")
		else
			local pl = minetest.get_player_by_name(name)
			local all_objects = minetest.get_objects_inside_radius({x=pl:getpos().x, y=pl:getpos().y, z=pl:getpos().z}, radius)

			for _,player in ipairs(all_objects) do
				if player:is_player() then
					local target = player:get_player_name()
					-- Checking if the target is in this channel
					if playersChannels[target][main_channel_name] then
						if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
							minetest.chat_send_player(target, format_message(whisper_string, {
								channel_name = main_channel_name, from_player = name, message = msg, color = whisper_color
							}))
						end
					end
				end
			end
			return true
		end
	end
end)

minetest.register_on_chat_message(function(name, message)
	local msg = message
	local channel_name = currentPlayerChannel[name]

	if not channels[channel_name] then
		minetest.chat_send_player(name, "Channel "..channel_name.." does not exist, switching back to "..main_channel_name..". Please resend your message")
		currentPlayerChannel[name] = main_channel_name
		minetest.get_player_by_name(name):set_attribute("beerchat:current_channel", main_channel_name)
		return true
	end

	if not channels[channel_name] then
		minetest.chat_send_player(name, "Channel "..channel_name.." does not exist")
	elseif msg == "" then
		minetest.chat_send_player(name, "Please enter the message you would like to send to the channel")
	elseif not playersChannels[name][channel_name] then
		minetest.chat_send_player(name, "You need to join this channel in order to be able to send messages to it")
	else
		for _,player in ipairs(minetest.get_connected_players()) do
			local target = player:get_player_name()
			-- Checking if the target is in this channel
			if playersChannels[target][channel_name] then
				if not minetest.get_player_by_name(target):get_attribute("beerchat:muted:"..name) then
					minetest.chat_send_player(target, format_message(main_channel_message_string, { channel_name = channel_name, from_player = name, message = message }))
					if channel_name ~= main_channel_name and enable_sounds then
						minetest.sound_play(channel_message_sound, { to_player = target, gain = 1.0 } )
					end
				end
			end
		end
	end
	return true
end)
