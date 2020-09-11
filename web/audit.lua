-- auth fail
minetest.register_on_auth_fail(function(name, ip)
	beerchat.on_channel_message("audit", nil, "Player '" .. name ..
		"' from ip " .. ip .. " tried to connect with wrong password")
end)

-- anticheat
minetest.register_on_cheat(function(player, cheat)
	local playername = player:get_player_name()
	local type = cheat.type
	beerchat.on_channel_message("audit", nil, "Player '" .. playername ..
		"' triggered anticheat: '" .. (type or "<unknown>") ..
		"' at position: " .. minetest.pos_to_string(vector.floor(player:get_pos())))
end)

-- noclip check

local solid_nodes = {
  ["default:stone"] = true,
  ["default:sand"] = true,
  ["default:gravel"] = true
}

-- playername -> count
local noclip_counters = {}

-- set counter
minetest.register_on_joinplayer(function(player)
  noclip_counters[player:get_player_name()] = 0
end)

-- clear counter
minetest.register_on_leaveplayer(function(player)
  noclip_counters[player:get_player_name()] = nil
end)

-- check players
local function check_player_node()
  for _, player in ipairs(minetest.get_connected_players()) do
    if not minetest.check_player_privs(player:get_player_name(), "noclip") then
      -- noclip not granted
      local pos = player:get_pos()
      local playername = player:get_player_name()
      local node = minetest.get_node(pos)
      if node.name and solid_nodes[node.name] then
        noclip_counters[playername] = noclip_counters[playername] + 1

        if noclip_counters[playername] > 10 then
          -- report possible clientside noclip cheat
          local msg = "Player '" .. playername .. "' " ..
            " was caught inside a solid node" ..
            " last at position: " .. minetest.pos_to_string(vector.floor(player:get_pos()))
          beerchat.on_channel_message("audit", nil, msg)
          minetest.log("action", "[beerchat audit] " .. msg)

          noclip_counters[playername] = 0
        end
      end
    end
  end

  minetest.after(1, check_player_node)
end

minetest.after(1, check_player_node)
