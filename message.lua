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
-- ${to_player} player to which the message is sent, will contain multiple player names
-- e.g. when sending a PM to multiple players
-- ${message} the actual message that is to be sent
-- ${time} the current time in 24 hour format, as returned from os.date("%X")
--

local send_on_local_channel = function(msg)
	for _,player in ipairs(minetest.get_connected_players()) do
		local target = player:get_player_name()
		-- Checking if the target is in this channel
		if beerchat.execute_callbacks('on_send_on_channel', msg, target) then
			beerchat.send_message(
				target,
				beerchat.format_message(
					beerchat.main_channel_message_string, {
						channel_name = msg.channel,
						to_player = target,
						from_player = msg.name,
						message = msg.message
					}
				),
				msg.channel
			)
		end
	end
end

beerchat.send_on_local_channel = function(msg)
	if beerchat.execute_callbacks('before_send_on_channel', msg) then
		send_on_local_channel(msg)
	end
end

beerchat.send_on_channel = function(msg, ...)
	-- FIXME: Backwards compatibility hack, args deliberately made hard to read.
	-- Remove this once everything uses table all the way through message handling.
	msg = type(msg) == "table" and msg or {name=msg, channel=arg[1], message=arg[2]}
	-- Execute registered event handlers, abort if told to do so
	if beerchat.execute_callbacks('before_send_on_channel', msg) then
		-- Log and deliver message to both local and remote platforms
		minetest.log("action", "[beerchat] CHAT #" .. msg.channel .. " <" .. msg.name .. "> " .. msg.message)
		beerchat.on_channel_message(msg.channel, msg.name, msg.message)
		send_on_local_channel(msg)
	end
end

beerchat.register_callback("on_send_on_channel", function(msg, target)
	if not beerchat.is_player_subscribed_to_channel(target, msg.channel)
		or beerchat.has_player_muted_player(target, msg.name) then
		return false
	end
end)
