
function format_string(s, tab)
  return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

beerchat.format_message = function(s, tab)
	local owner
	local password
	local color = beerchat.default_channel_color

	if tab.channel_name and beerchat.channels[tab.channel_name] then
		owner = beerchat.channels[tab.channel_name].owner
		password = beerchat.channels[tab.channel_name].password
		color = beerchat.channels[tab.channel_name].color
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

	return minetest.colorize(color, format_string(s, params))
end