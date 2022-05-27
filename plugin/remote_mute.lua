local remote_muted = {}

minetest.register_chatcommand("remote_mute", {
	params = "<Player Name> [<Player Name> ...]",
	description = ("Mute remote users. Requires %s privilege."):format(beerchat.jail.priv),
	privs = { [beerchat.jail.priv] = true },
	func = function(name, param)
    -- Mute remote player
    local names = string.gmatch(param, "[^%s,]+")
    for name in names do
      remote_muted[name] = true
    end
    return true
  end
})

minetest.register_chatcommand("remote_unmute", {
	params = "[<Player Name> <Player Name> ...]",
	description = ("Unmute remote users or list muted remote users. Requires %s privilege."):format(beerchat.jail.priv),
	privs = { [beerchat.jail.priv] = true },
	func = function(name, param)
    if not param or param == "" then
      local names = {}
      for name,_ in pairs(remote_muted) do
        table.insert(names, name)
      end
      if #names > 0 then
        minetest.chat_send_player(name, "Muted remote users: " .. table.concat(names, ", "))
      else
        minetest.chat_send_player(name, "No muted remote users.")
      end
    else
      local names = string.gmatch(param, "[^%s,]+")
      for name in names do
        remote_muted[name] = nil
      end
    end
    return true
  end
})

beerchat.register_callback('on_http_receive', function(msg_data)
	if msg_data.name and remote_muted[msg_data.name] then
    return false
  end
end)
