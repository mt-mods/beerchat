

minetest.register_chatcommand("logout", {
	description = "logs out the remote user (irc, discord)",
	func = function(name)
    beerchat.remote_username_map[name] = nil
    beerchat.save_remote_usernames()
    return true, "Logged out!"
  end
})
