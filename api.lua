w_api = {}

local w_engine = {}
w_engine.players = {}

minetest.register_on_leaveplayer(function(obj, timed_out)
    local name = obj:get_player_name()
    w_engine.players[name] = nil
end)

function w_api.register_weapon(name, def)
    local defaults = {
        ent_bl = true,
        crit_mp = 1.5,
        kb_mp = 2,
        slash_dir = "left",
        swing_delay = 0.5,
        dmg = 2,
        delay = 0.1,
        depth = 1,
        range = 4,
        spread = 10,
        amount = 4,
    }

    for key, value in pairs(def.primary_use) do
        defaults[key] = value or defaults[key]
    end

    minetest.register_craftitem(name, {
        description = def.description,
        inventory_image = def.inventory_image,
        wield_scale = def.wield_scale or {x = 2, y = 2, z = 1},

        primary_use = defaults,
        secondary_use = def.secondary_use or nil,

        on_use = function(itemstack, user, pointed_thing)
            w_engine.on_click(user, def.primary_use)
        end,

        on_secondary_use = function(itemstack, user, pointed_thing)
            if def.secondary_use then
                w_engine.on_click(user, def.secondary_use)
            end
        end,
        
        on_place = function(itemstack, placer, pointed_thing)
            if def.secondary_use then
                w_engine.on_click(placer, def.secondary_use)
            end
        end,
    })
end

function w_engine.on_click(user, def)
    local name = user:get_player_name()
    local current = minetest.get_us_time() / 1000000
    local interval = def.swing_delay

    if not w_engine.players[name] or current - w_engine.players[name].current > interval then
        w_engine.players[name] = {current = current, interval = interval}

        minetest.after(def.swing_delay, w_engine.swing, user, def)
    end
end

function w_engine.swing(user, def)
    if user then
        local timer = 0

        local dirs = {left = 1, right = -1}
        local slash_dir = dirs[def.slash_dir]

        local objs
        if def.ent_bl == true then
            objs = {}
        end

        for mp = 1, def.amount do
            minetest.after(timer, w_engine.do_raycast, user, objs, def, mp)
            timer = timer + def.delay
        end
    end
end

function w_engine.do_raycast(user, objs, def, count)
    local cam = {x = minetest.yaw_to_dir(user:get_look_yaw()), z = user:get_look_dir()}
    local p_pos = user:get_pos()
    p_pos.y = p_pos.y + user:get_properties().eye_height or 1.625

    local dir = vector.multiply(minetest.yaw_to_dir(math.rad(def.spread * count)), def.range)
    local e_pos = vector.add(p_pos, vector.multiply(cam.z, dir.z))
    e_pos = vector.add(e_pos, vector.multiply(cam.x, dir.x))

    local depth = 0

    for pointed_thing in minetest.raycast(p_pos, e_pos, true, false) do
        if depth < def.depth then
            w_engine.handle_ray(user, objs, pointed_thing, def, e_pos, depth)
        end
    end
end

function w_engine.handle_ray(user, objs, pointed_thing, def, dir, depth)
    if pointed_thing.type == "object" then
        if pointed_thing.ref ~= user and objs and not objs[pointed_thing.ref] then
            local vel = user:get_player_velocity()
            local spd = math.sqrt((vel.x * vel.x) + (vel.z * vel.z))

            pointed_thing.ref:punch(user, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy = def.dmg}})

            if pointed_thing.ref:is_player() then
                pointed_thing.ref:add_player_velocity(vector.multiply(user:get_look_dir(), def.kb_mp * spd))
            else
                pointed_thing.ref:add_velocity(vector.multiply(user:get_look_dir(), def.kb_mp * spd))
            end
        end

        if objs then
            depth = depth + 1
            objs[pointed_thing.ref] = pointed_thing.ref

            return depth, objs
        end
    end
end