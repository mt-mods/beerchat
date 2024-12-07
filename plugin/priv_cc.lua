-- if you need to set a special name for privilege, use "beerchat.name_priv_cc = spec_name" in minetest.conf
local name_priv2cc = minetest.settings:get("beerchat.priv_cc.name")
if name_priv2cc == '' then name_priv2cc = 'chat_creator' end
minetest.log("info", "to create channel add new priv: " .. name_priv2cc)
minetest.register_privilege(name_priv2cc, {
        description = "Allows you to create a channel (mod beerchat)",
        give_to_singleplayer = false
})
