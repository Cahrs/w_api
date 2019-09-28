local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath.."/api.lua")

w_api.register_weapon("w_api:sword", {
    description = "Large Sword",
    inventory_image = "w_api_sword.png",
    primary_use = {ent_bl = true, crit_mp = 1.5, kb_mp = 2, swing_delay = 0.3, slash_dir = "left", dmg = 2, delay = 0.1, depth = 1, range = 4, spread = 10, amount = 4},
})

minetest.register_entity("w_api:test", {
    initial_properties = {
        hp_max = 10,
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        visual = "upright_sprite",
        visual_size = {x = 1, y = 1},
        textures = {"w_api_sword.png"},
    },
})