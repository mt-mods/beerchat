-- default relay commands

-- !players
beerchat.register_relaycommand("players", function()
    if #minetest.get_connected_players() == 0 then
        return "No players online"
    end

    local msg = "List of players: "
    for _, player in ipairs(minetest.get_connected_players()) do
        msg = msg .. player:get_player_name() .. ","
    end
    -- strip trailing comma
    msg = string.sub(msg, 1, #msg-1)

    return msg
end)
