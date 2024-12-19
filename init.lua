mcl_mobs.register_mob("bongledons:bongledon", {
    description = "Bongledon",
    type = "monster",
    spawn_class = "hostile",
    hp_min = 20,
    hp_max = 30,
    xp_min = 5,
    xp_max = 5,
    visual = "mesh",
    mesh = "mobs_mc_zombie.b3d",
    textures = {
        {
            "mobs_mc_empty.png",
            "mobs_mc_zombie.png"
        }
    },
    collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.6, 0.3},
    
    --Default behavior logic is downright abysmal. Doing just about everything custom
    on_spawn = function(self)
        self._EYE_HEIGHT = 1.2
        self._SIGHT_RANGE = 30
        self._ENEMIES = {"player"}
        self._friends = {}
        self._camp = nil
        self._target = nil
    end,
    do_punch = function(self, hitter)
        self._target = hitter
    end,
    do_custom = function(self, dtime)
        local eye_pos = vector.add(self.object:get_pos(), vector.new(0, self._EYE_HEIGHT, 0))
        if self._target then
            -- We have a target! TODO: attack them
        else
            -- Looking for target
            local objects = minetest.get_objects_inside_radius(eye_pos, self._SIGHT_RANGE)
            local potential_targets = {}
            for _, obj in pairs(objects) do
                local name = ""
                if obj:is_player() then
                    if mcl_gamemode.get_gamemode(obj) == "survival" then
                        name = "player"
                    end
                else
                    local ent = obj:get_luaentity()
                    name = ent.type or ""
                end
                if minetest.line_of_sight(eye_pos, obj:get_pos(), 5 * math.pi / 12) and -- Not obscured
                   math.abs(minetest.dir_to_yaw(vector.subtract(obj:get_pos(), eye_pos)) % 360 - self.object:get_yaw() % 360) < 37.5 then -- In view range
                    -- Can see potential target.
                    local is_enemy = false
                    for i = 1, #self._ENEMIES do
                        if self._ENEMIES[i] == name then
                            is_enemy = true
                        end
                    end
                    if is_enemy then
                        -- I hate this type of entity! Add it to list of potential targets.
                        minetest.log("I see you!")
                        potential_targets[#potential_targets + 1] = obj
                    end
                end
            end
            if #potential_targets > 0 then
                self._target = potential_targets[math.random(#potential_targets)]
            end
        end
    end
})
mcl_mobs.register_egg("bongledons:bongledon", "Bongledon", "#009900", "#008000")