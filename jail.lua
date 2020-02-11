beerchat.jail_list = {}

if nil == beerchat.jail_channel_name or "" == beerchat.jail_channel_name then
	beerchat.jail_channel_name = "wail"
end

beerchat.is_player_jailed = function(name)
	return true == beerchat.jail_list[name]
end
