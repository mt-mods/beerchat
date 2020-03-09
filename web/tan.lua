
beerchat.tan_map = {}

minetest.register_chatcommand("remote_tan", {
  description = "creates a temporary access number for the /login command",
  func = function(name)
    local tan = "" .. math.random(1000, 9999)
    beerchat.tan_map[name] = tan
    return true, "Your tan is " .. tan .. ", it will expire upon leaving the game"
  end
})

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	beerchat.tan_map[name] = nil
end)
