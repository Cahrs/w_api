w_api = {}

local w_engine = {}
w_engine.players = {}

minetest.register_on_leaveplayer(function(obj, timed_out)
    local name = obj:get_player_name()
    w_engine.players[name] = nil
end)

local function check_bools(func, itemstack, user, obj)
    local bool

    if obj then
        bool = func(itemstack, user, obj)
    else
        bool = func(itemstack, user)
    end

    return bool
end

local function secondary_use(itemstack, user, def, calls)
    if def and (not calls.secondary_use or not calls.secondary_use.on_use or check_bools(calls.secondary_use.on_use, itemstack, user)) then
        w_engine.on_click(itemstack, user, def.secondary_use, calls.secondary_use)
    end
end

function w_api.register_weapon(name, def)
    local defaults = {
        ent_bl = true,
        crit_mp = 1.5,
        kb_mp = 2,
        slash_dir = "left",
        swing_delay = 0.5,
        delay = 0.1,
        depth = 1,
        range = 4,
        spread = 10,
        amount = 4,

        damage_groups = {fleshy = 2}
    }

    for key, value in pairs(def.primary_use) do
        defaults[key] = value or defaults[key]
    end

    local calls = {
        primary_use = def.callbacks.primary_use or nil,
        secondary_use = def.callbacks.secondary_use or nil,
    }

    minetest.register_craftitem(name, {
        description = def.description,
        inventory_image = def.inventory_image,
        wield_scale = def.wield_scale or {x = 2, y = 2, z = 1},

        callbacks = calls,

        primary_use = defaults,
        secondary_use = def.secondary_use or nil,

        on_use = function(itemstack, user, pointed_thing)
            if not calls or not calls.primary_use
            or not calls.primary_use.on_use or check_bools(calls.primary_use.on_use, itemstack, user) then
                --minetest.chat_send_all(dump(calls))
                w_engine.on_click(itemstack, user, defaults, calls.primary_use)
            end
        end,

        on_secondary_use = function(itemstack, user, pointed_thing)
            secondary_use(itemstack, user, def.secondary_use, calls)
        end,

        on_place = function(itemstack, placer, pointed_thing)
            secondary_use(itemstack, placer, def, calls)
        end,
    })
end

function w_engine.on_click(itemstack, user, def, calls)
    local name = user:get_player_name()
    local current = minetest.get_us_time() / 1000000
    local interval = def.swing_delay

    if not w_engine.players[name] or current - w_engine.players[name].current > interval then
        w_engine.players[name] = {current = current, interval = interval}

        minetest.after(def.swing_delay, w_engine.swing, itemstack, user, def, calls)
    end
end

function w_engine.swing(itemstack, user, def, calls)
    if user then
        local timer = 0
        local amount = def.amount

        local dirs = {left = 1, right = -1}
        local slash_dir = dirs[def.slash_dir]

        local objs
        if def.ent_bl == true then
            objs = {}
        end

        --[[]]
        for count = (amount * slash_dir) / 2, (-amount * slash_dir) / 2, -1 * slash_dir do
            minetest.after(timer, w_engine.do_raycast, itemstack, user, def, calls, objs, count)
            timer = timer + def.delay
        end
    end
end

function w_engine.do_raycast(itemstack, user, def, calls, objs, count)
    local cam = {x = minetest.yaw_to_dir(user:get_look_yaw()), z = user:get_look_dir()}
    local p_pos = user:get_pos()
    p_pos.y = p_pos.y + user:get_properties().eye_height or 1.625

    local dir = vector.multiply(minetest.yaw_to_dir(math.rad(def.spread * count)), def.range)
    local e_pos = vector.add(p_pos, vector.multiply(cam.z, dir.z))
    e_pos = vector.add(e_pos, vector.multiply(cam.x, dir.x))

    local depth = 0

    for pointed_thing in minetest.raycast(p_pos, e_pos, true, false) do
        if depth < def.depth then
            w_engine.handle_ray(itemstack, user, def, calls, objs, depth, pointed_thing)
        end
    end
end

function w_engine.handle_ray(itemstack, user, def, calls, objs, depth, pointed_thing)
    if pointed_thing.type == "object" then
        if pointed_thing.ref ~= user and (not objs or objs and not objs[pointed_thing.ref])
        and (not calls or not calls.on_hit or check_bools(calls.on_hit, itemstack, user, pointed_thing.ref)) then
            local vel = user:get_player_velocity()
            local spd = math.sqrt((vel.x * vel.x) + (vel.z * vel.z))

            pointed_thing.ref:punch(user, 1.0, {full_punch_interval = 1.0, damage_groups = def.damage_groups})

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