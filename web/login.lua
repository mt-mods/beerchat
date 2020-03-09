
minetest.register_chatcommand("login", {
  params = "username <password|tan>",
	description = "logs in as another user (only useful for remote commands, irc, discord, etc)",
	func = function(name, param)
    if not param or param == "" then
      return true, "Logged in as: '" .. beerchat.get_mapped_username(name) .. "'"
    end

    local mapped_username, password
    local i = 1

    for str in param:gmatch("%S+") do
      if i == 1 then mapped_username = str end
      if i == 2 then password = str end
      i = i + 1
    end

    if not mapped_username or not password then
      return false, "Usage: /login username <password|tan>"
    end

    -- verify tan
    if beerchat.tan_map[mapped_username] == password then
      beerchat.remote_username_map[name] = mapped_username
      beerchat.save_remote_usernames()
      return true, "Logged in as '" .. mapped_username .. "'"
    end

    local handler = minetest.get_auth_handler()
    local entry = handler.get_auth(mapped_username)
    if not entry then
      return false, "Could not get auth entry!"
    end

    if minetest.check_password_entry(mapped_username, entry.password, password) then
      beerchat.remote_username_map[name] = mapped_username
      beerchat.save_remote_usernames()
      return true, "Logged in as '" .. mapped_username .. "'"
    end

  end
})
