local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath.."/api.lua")

w_api.register_weapon("w_api:sword", {
    description = "Large Sword",
    inventory_image = "w_api_sword.png",
    rays = {dmg = 2, delay = 0.1, depth = 1, range = 4, spread = 10, amount = 4},
    delay = 0.3,
    slash_dir = 0
})