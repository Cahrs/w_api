w_api = {}

local w_engine = {}
w_engine.players = {}

minetest.register_on_leaveplayer(function(obj, timed_out)
    local name = obj:get_player_name()
    w_engine.players[name] = nil
end)

function w_engine.on_click(user, item)
    local name = user:get_player_name()
    local current = minetest.get_us_time() / 1000000
    local interval = item.swing_delay * (item.amount + 1)
    w_engine.players[name] = w_engine.players[name] or {current = current, interval = interval}
    --minetest.chat_send_all("interval: " .. interval)
    if current - w_engine.players[name].current > interval then
        w_engine.players[name].current = current
        w_engine.players[name].interval = interval
        --minetest.chat_send_all("delay is over")
        minetest.after(item.swing_delay or 0, w_engine.swing, user, item)
    end
end

function w_api.register_weapon(itemname, descrip)
    minetest.register_craftitem(itemname, {
        description = descrip.description,
        inventory_image = descrip.inventory_image,
        wield_scale = {x = 2, y = 2, z = 1} or descrip.wield_scale,
        primary_use = descrip.primary_use or {ent_bl = true, crit_mp = 1.5, kb_mp = 2, slash_dir = "left", swing_delay = 0.5, dmg = 2, delay = 0.1, depth = 0.1, range = 4, spread = 10, amount = 4},
        secondary_use = descrip.secondary_use or {ent_bl = true, crit_mp = 1.5, kb_mp = 2, slash_dir = "left", swing_delay = 0.3, dmg = 2, delay = 0.1, depth = 0.1, range = 4, spread = 10, amount = 4},
        on_use = function(itemstack, user, pointed_thing)
            w_engine.on_click(user, minetest.registered_items[itemname].primary_use)
        end,
        --secondary use is not fully-supported/ready-to-use due to builtin api functions limitations
        --[[on_place = function(itemstack, user, pointed_thing)
            w_engine.on_click(user, minetest.registered_items[itemname].secondary_use)
        end]]
    })
end

function w_engine.swing(user, item)
    if user then
        local delay = item.delay or nil
        local timer = 0
        local depth = 0
        local amount = item.amount
        if item.slash_dir == "left" then
            mp = 1
        elseif item.slash_dir == "right" then
            mp = -1
        end

        if item.ent_bl and item.ent_bl == true then
            objs = {}
        end

        for i = (amount * mp) / 2, (-amount * mp) / 2, -1 * mp do
            if delay then
                minetest.after(timer, w_engine.do_raycast, user, objs, item, i)
                timer = timer + delay
            else
                w_engine.do_raycast(user, objs, item, i)
            end
        end
    end
end

function w_engine.do_raycast(user, objs, item, count)
    local cam_z = user:get_look_dir()
    local cam_x = minetest.yaw_to_dir(user:get_look_yaw())
    local p_pos = user:get_pos()
    p_pos.y = p_pos.y + user:get_properties().eye_height or 1.625
    local dir = vector.multiply(minetest.yaw_to_dir(math.rad(item.spread * count)), item.range)
    local e_pos = vector.add(p_pos, vector.multiply(cam_z, dir.z))
    e_pos = vector.add(e_pos, vector.multiply(cam_x, dir.x))
    local depth = 0

    for pointed_thing in minetest.raycast(p_pos, e_pos, true, false) do
        --minetest.add_particle({pos = pointed_thing.intersection_point, expirationtime = 2, size = 2, collisiondetection = false, vertical = false, texture = "w_api_dust.png"})
        if item.depth and depth >= item.depth then
            return
        end
        w_engine.handle_ray(user, objs, pointed_thing, item, e_pos, depth)
    end
end

function w_engine.handle_ray(user, objs, pointed_thing, item, dir, depth)
    --print("intesection normal: " .. dump(pointed_thing.intersection_normal))
    --print(pointed_thing.intersection_normal)
    if pointed_thing.type ~= "object" then
        return           
    elseif pointed_thing.type == "object" then
        if objs and objs[pointed_thing.ref] and pointed_thing.ref ~= user then
            --minetest.chat_send_all("mob already hit by previous ray, aborting")
            return
        elseif objs and pointed_thing.ref ~= user then
            --minetest.chat_send_all("mob not previously hit, adding to table")
            objs[pointed_thing.ref] = pointed_thing.ref
            --print(objs[pointed_thing.ref])
        end

        local vel = user:get_player_velocity()
        local spd = math.sqrt((vel.x * vel.x) + (vel.z * vel.z))
        if spd <= 0 then
            spd = 1
        end
        local dmg = item.dmg
        if vel.y <= -1 then
            local dmg = dmg * item.crit_mp
            --print("critical hit!: " .. dmg)
        end

        if pointed_thing.ref ~= user then
            pointed_thing.ref:punch(user, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy = dmg}})
        end
        if pointed_thing.ref:is_player() and pointed_thing.ref ~= user then
            pointed_thing.ref:add_player_velocity(vector.multiply(user:get_look_dir(), item.kb_mp * spd))
        else
            pointed_thing.ref:add_velocity(vector.multiply(user:get_look_dir(), item.kb_mp * spd))
        end
        if depth and not objs then
            depth = depth + 1
            return depth
        elseif depth and objs then
            return depth, objs
        end
    end
end