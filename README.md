# w_api

```
Information:  
    Adds a melee weapons api for more advanced/deep combat within Minetest  

Features:  
    Support for custom damage groups,  
    Primary and secondary attacks,  
    Variable slash depth and weapon reach,  
    Directional slashes,  
    Customizable swing delay and time per weapon,  
    Critical hits,  

    more..?  

Usage (modders):  
    w_api allows easily creating highly customizable weapons via *w_api.register_weapon*

    Example usage:  
        w_api.register_weapon(name, def)  

    Parameters:  
        primary_use / secondary_use (table) parameters:  
            ent_bl -- if true disallow from multiple rays hitting the same obj  
            crit_mp -- value multiplied by damage groups when hitter has a negative Y velocity  
            kb_mp -- value to multiply by player / ent speed for knockback  
            slash_dir -- "left": right -> left; "right": left -> right slash direction  
            swing_delay -- time (in seconds) until swing start  
            delay -- delay (in seconds) between each ray in a swing  
            depth -- how many objs deep in a crowd that each ray can damage  
            range -- sword reach (in meters)  
            spread -- angle (in degrees) between each ray in a swing  
            amount -- the amount of rays in a sword swing  
            damage_groups -- a table of damage groups  

        callbacks (table) parameters  
            primary_use / secondary_use (table) parameters  
                on_use -- function to be called on weapon swing,  
                        run arbitrary code and then return true or false to continue with the calculations  
                on_hit -- function to be called on obj hit,  
                        run arbitrary code and then return true or false to continue with the calculations  

        wield_scale -- the weapons wielded scale  

        Misc:  
            inventory_image  
            description  
```