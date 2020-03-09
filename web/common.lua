
function beerchat.get_mapped_username(name)
  local mapped_username = beerchat.remote_username_map[name]
  return mapped_username or name
end

function beerchat.save_remote_usernames()
  beerchat.mod_storage:set_string("remote_usernames", minetest.write_json(beerchat.remote_username_map))
end

-- load remote usernames initially
beerchat.remote_username_map = minetest.parse_json(beerchat.mod_storage:get_string("remote_usernames")) or {}
