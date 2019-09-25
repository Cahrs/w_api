w_api = {}

local w_engine = {}
w_engine.players = {}

function w_api.register_weapon(itemname, descrip)
    minetest.register_craftitem(itemname, {
        description = descrip.description,
        inventory_image = descrip.inventory_image,
        wield_scale = {x = 2, y = 2, z = 1} or descrip.wield_scale,
        rays = descrip.rays or {dmg = 2, delay = 0.1, depth = 0.1, range = 4, spread = 10, amount = 4},
        slash_dir = descrip.slash_dir or 0,
        delay = descrip.delay or 0.5,
        on_use = function(itemstack, user, pointed_thing)
            local name = user:get_player_name()
            local current = minetest.get_us_time() / 1000000
            w_engine.players[name] = w_engine.players[name] or current
            local interval = minetest.registered_items[itemname].rays.delay * (minetest.registered_items[itemname].rays.amount + 1)
            --minetest.chat_send_all("interval: " .. interval)
            if current - w_engine.players[name] > interval then
                w_engine.players[name] = current
                --minetest.chat_send_all("delay is over")
                minetest.after(minetest.registered_items[itemname].delay, w_engine.swing, user, itemname)
            end
        end
    })
end

function w_engine.swing(user, itemname)
    if user then
        local item = minetest.registered_items[itemname]
        local delay = item.rays.delay or nil
        local timer = 0
        local depth = 0
        local amount = item.rays.amount
        if item.slash_dir == 0 then
            mp = 1
        elseif item.slash_dir == 1 then
            mp = -1
        end

        for i = (-amount * mp) / 2, (amount * mp) / 2, 1 * mp do
            if delay then
                minetest.after(timer, w_engine.do_raycast, user, item, i)
                timer = timer + delay
            else
                w_engine.do_raycast(user, item, i)
            end
        end

    end
end

function w_engine.do_raycast(user, item, count)
    local cam_z = user:get_look_dir()
    local cam_x = minetest.yaw_to_dir(user:get_look_yaw())
    local p_pos = user:get_pos()
    p_pos.y = p_pos.y + user:get_properties().eye_height or 1.625
    local dir = vector.multiply(minetest.yaw_to_dir(math.rad(item.rays.spread * count)), item.rays.range)
    local e_pos = vector.add(p_pos, vector.multiply(cam_z, dir.z))
    e_pos = vector.add(e_pos, vector.multiply(cam_x, dir.x))
    local depth = 0

    for pointed_thing in minetest.raycast(p_pos, e_pos, true, false) do
        --minetest.add_particle({pos = pointed_thing.intersection_point, expirationtime = 2, size = 2, collisiondetection = false, vertical = false, texture = "w_api_dust.png"})
        if item.rays.depth and depth >= item.rays.depth then
            return
        end
        w_engine.handle_ray(user, pointed_thing, item, e_pos2, depth)
    end
end

function w_engine.handle_ray(user, pointed_thing, item, dir, depth)
    --print("intesection normal: " .. dump(pointed_thing.intersection_normal))
    --print(pointed_thing.intersection_normal)
    if pointed_thing.type ~= "object" then
        return           
    elseif pointed_thing.type == "object" then
        if pointed_thing.ref ~= user then
            pointed_thing.ref:punch(user, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy = item.rays.dmg}})
        end
        local vel = user:get_player_velocity()
        local spd = math.sqrt((vel.x * vel.x) + (vel.z * vel.z))
        if spd <= 0 then
            spd = 1
        end
        if pointed_thing.ref:is_player() and pointed_thing.ref ~= user then
            pointed_thing.ref:add_player_velocity(vector.multiply(user:get_look_dir(), 2 * spd))
        else
            pointed_thing.ref:add_velocity(vector.multiply(user:get_look_dir(), 2 * spd))
        end
        if depth then
            depth = depth + 1
            return depth
        end
    end
end