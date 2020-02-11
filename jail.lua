beerchat.jail_list = {}

beerchat.is_player_jailed = function(name)
	return true == beerchat.jail_list[name]
end
