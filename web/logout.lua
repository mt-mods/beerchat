

minetest.register_chatcommand("logout", {
	description = "logs out the remote user (irc, discord)",
	func = function(name)
    for key, mapped_username in pairs(beerchat.remote_username_map) do
      if mapped_username == name then
        beerchat.remote_username_map[key] = nil
        beerchat.save_remote_usernames()
        return true, "Logged out!"
      end
    end

    return false, "No user found to log out!"
  end
})
