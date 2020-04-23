# w_api

Adds a melee weapons api for more advanced/deep combat within Minetest.  

## Features
* Support for custom damage groups
* Primary and secondary attacks
* Variable slash depth and weapon reach
* Directional slashes
* Customizable swing delay and time per weapon
* Critical hits
* ???

## Usage (mods)
`w_api.register_weapon(name, weapon definition)`:

Weapon Definition
-----------------
Used by `w_api.register_weapon`.

```
{
    description = "Super cool weapon",

    wield_scale = {x = 1, y = 1, z = 1},
    -- Weapon wield scale (see Minetest lua_api.txt)

    inventory_image = "your_weapon.png",

    ent_bl = false, 
    -- If true, objects will only be hit once (rather than by multiple raycasts).

    crit_mp = 1,
    -- Value multiplied by damage groups when hitter has a negative Y velocity.
    
    kb_mp = 1,
    -- Value to multiply by player / ent speed for knockback.

    slash_dir = "left",
    -- Weapon slash-to direction (eg. right-to-left).

    swing_delay = 1,
    -- Time (in seconds) until swing starts.

    delay = 1,
    -- Delay (in seconds) between each raycast in a swing.
    
    depth = 3,
    -- How many objects deep that a weapon can damage.

    range = 5,
    -- Sword reach (in nodes).

    spread = 20,
    -- Angle (in degrees) between each raycast in a swing.
    
    amount = 10,
    -- Ray count in a sword swing.

    damage_groups = {}
    -- A table of damage groups (see Minetest lua_api.txt).


    on_use = function(itemstack, user, pointed_thing),
    -- Function to be called when weapon is used.
    -- Return false to prevent default behavior.

    on_hit = function(itemstack, hitter, pointed_thing),
    -- Function to be called when an object is hit by the weapon.
    -- Return false to prevent default behavior.
}
```
