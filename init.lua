local function is_path_direct(path)
    local direct = true
    if #path >= 2 then
        local sum_delta_theta = 0
        local last_angle = 0
        for i = 1, #path - 1 do
            local current_point = path[i]
            local next_point = path[i + 1]
            if next_point.y ~= current_point.y then
                direct = false
                break
            end
            if last_angle then
                sum_delta_theta = sum_delta_theta + last_angle - minetest.dir_to_yaw(vector.subtract(next_point, current_point))
            end
            last_angle = minetest.dir_to_yaw(vector.subtract(next_point, current_point))
        end
        if sum_delta_theta > 0.01 then
            direct = false
        end
    end
    return direct
end

local EYE_HEIGHT = 1.2
local SIGHT_RANGE = 30
local ENEMIES = {"player", "mobs_mc:sheep"}
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
    stepheight = 1.1,
    fear_height = 3,
    
    --Default behavior logic is downright abysmal. Doing just about everything custom
    on_spawn = function(self)
        self.bongledon = {
            friends = {},
            camp = nil,
            target = nil,
            going = false
        }
    end,
    do_punch = function(self, hitter)
        self.bongledon.target = hitter
    end,
    do_custom = function(self, dtime)
        local pos = self.object:get_pos()
        local eye_pos = vector.add(pos, vector.new(0, EYE_HEIGHT, 0))

        -- Targeting/attacking
        if self.bongledon.target then
            -- We have a target!
            local enemy_pos = self.bongledon.target:get_pos()
            if vector.distance(pos, enemy_pos) <= 2 then
                -- TODO: attack
                return
            end
            if not self.bongledon.going then
                minetest.log("Going")
                self.bongledon.going = true
                self:gopath(enemy_pos)
            else
                -- Adjust to moving target
                -- Determine if we are in the same "room" as target by checking if the path is direct
                local path = minetest.find_path(pos, enemy_pos, 100, self.stepheight, self.fear_height - 1)
                if not path then return true end
                if is_path_direct(path) then
                    -- Hacky way to force gopath to stop
                    self._target = pos
                    minetest.log("Is direct")
                    -- TODO: make a custom direct path (for moving targets)
                end
            end
        else
            -- Looking for target
            local objects = minetest.get_objects_inside_radius(eye_pos, SIGHT_RANGE)
            local potential_targets = {}
            for _, obj in pairs(objects) do
                local name = ""
                if obj:is_player() then
                    if mcl_gamemode.get_gamemode(obj) == "survival" then
                        name = "player"
                    end
                else
                    local ent = obj:get_luaentity()
                    name = ent.name or ""
                end
                if minetest.line_of_sight(eye_pos, obj:get_pos(), 2) and -- Not obscured
                   math.abs(minetest.dir_to_yaw(vector.subtract(obj:get_pos(), eye_pos)) % 360 - self.object:get_yaw() % 360) < 37.5 then -- In view range
                    -- Can see potential target.
                    local is_enemy = false
                    for i = 1, #ENEMIES do
                        if ENEMIES[i] == name then
                            is_enemy = true
                        end
                    end
                    if is_enemy then
                        -- I hate this type of entity! Add it to list of potential targets.
                        potential_targets[#potential_targets + 1] = obj
                    end
                end
            end
            if #potential_targets > 0 then
                self.bongledon.target = potential_targets[math.random(#potential_targets)]
            end
        end
    end
})
mcl_mobs.register_egg("bongledons:bongledon", "Bongledon", "#009900", "#008000")