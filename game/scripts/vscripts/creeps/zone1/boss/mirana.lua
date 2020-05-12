---------------
--HELPER FUNCTION
-----------------
function IsLuna(unit)
    if unit:GetUnitName() == "npc_boss_luna" then
        return true
    else
        return false
    end
end

--------------
--mirana shard
---------------
mirana_shard = class({
    GetAbilityTextureName = function(self)
        return "mirana_shard"
    end,
    GetIntrinsicModifierName = function(self)
        return "modifier_mirana_shard"
    end,
})

modifier_mirana_shard = class({
    IsDebuff = function(self)
        return false
    end,
    IsHidden = function(self)
        return true
    end,
    IsPurgable = function(self)
        return false
    end,
    RemoveOnDeath = function(self)
        return false
    end,
    AllowIllusionDuplicate = function(self)
        return true
    end,
    DeclareFunctions = function(self)
        return { MODIFIER_EVENT_ON_ATTACK_LANDED }
    end
})

function modifier_mirana_shard:OnCreated()
    if not IsServer() then
        return
    end
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
end

function modifier_mirana_shard:OnAttackLanded(keys)
    if not IsServer() then
        return
    end
    if (keys.attacker == self.parent) then
        self.mana_burn = self:GetAbility():GetSpecialValueFor("mana_burn") * 0.01
        self.void_per_burn = self:GetAbility():GetSpecialValueFor("void_per_burn") *0.01
        local Max_mana = keys.target:GetMaxMana()
        local burn = Max_mana * self.mana_burn

        local Mana = keys.target:GetMana()
        --if burn more than current mana burn equal to current mana
        if burn > Mana then
            burn = Mana
        end
        local damage = burn * self.void_per_burn
        keys.target:ReduceMana(burn)
        keys.target:EmitSound("Hero_Antimage.ManaBreak")
        local manaburn_pfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN_FOLLOW, keys.target)
        ParticleManager:SetParticleControl(manaburn_pfx, 0, keys.target:GetAbsOrigin() )
        ParticleManager:ReleaseParticleIndex(manaburn_pfx)

        local damageTable= {}
        damageTable.caster = keys.attacker
        damageTable.target = keys.target
        damageTable.ability = self.ability
        damageTable.damage = damage
        damageTable.voiddmg = true
        GameMode:DamageUnit(damageTable)
    end
end

LinkLuaModifier("modifier_mirana_shard", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)

--------------
--mirana sky
---------------

modifier_mirana_sky = class({
    IsDebuff = function(self)
        return true
    end,
    IsHidden = function(self)
        return false
    end,
    IsPurgable = function(self)
        return false
    end,
    RemoveOnDeath = function(self)
        return false
    end,
    AllowIllusionDuplicate = function(self)
        return true
    end,
    DeclareFunctions = function(self)
        return {MODIFIER_PROPERTY_FIXED_DAY_VISION,
                MODIFIER_PROPERTY_FIXED_NIGHT_VISION,
                MODIFIER_EVENT_ON_DEATH }
    end
})

function modifier_mirana_sky:OnCreated()
    if not IsServer() then
        return
    end
    self.caster = self:GetCaster()
    self.target = self:GetParent()
    self.ability = self:GetAbility()
    self.fixed_vision = self.ability:GetSpecialValueFor("fixed_vision")
    self:StartIntervalThink(29.5)
end

function modifier_mirana_sky:GetFixedDayVision()
    return self.fixed_vision
end

function modifier_mirana_sky:GetFixedNightVision()
    return self.fixed_vision
end

function modifier_mirana_sky:OnDeath(params)
    if (not IsServer()) then
        return
    end
    if params.unit == self.caster  then
        self:Destroy()
    end
end

function modifier_mirana_sky:OnIntervalThink()
    if (not IsServer()) then
        return
    end
    self.game_mode = GameRules:GetGameModeEntity()
    GameRules:BeginTemporaryNight(30)
end


LinkLuaModifier("modifier_mirana_sky", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)

mirana_sky = class({
    GetAbilityTextureName = function(self)
        return "mirana_sky"
    end,
})

function mirana_sky:OnSpellStart()
    if IsServer() then
        local caster = self:GetCaster()
        local caster_position = self:GetCaster():GetAbsOrigin()
        local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
                caster:GetAbsOrigin(),
                nil,
                30000,
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_ANY_ORDER,
                false)
        for _, enemy in pairs(enemies) do
            local modifierTable = {}
            modifierTable.ability = self
            modifierTable.target = enemy
            modifierTable.caster = caster
            modifierTable.modifier_name = "modifier_mirana_sky"
            modifierTable.duration = -1
            GameMode:ApplyDebuff(modifierTable)
        end
        caster:EmitSound("Hero_Nightstalker.Darkness.Team")
        local particle_moon = "particles/units/heroes/hero_mirana/mirana_moonlight_owner.vpcf"
        local particle_darkness = "particles/units/heroes/hero_night_stalker/nightstalker_ulti.vpcf"
        local particle_darkness_fx = ParticleManager:CreateParticle(particle_darkness, PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControl(particle_darkness_fx, 0, caster:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle_darkness_fx, 1, caster:GetAbsOrigin())
        Timers:CreateTimer(1.0, function()
            ParticleManager:DestroyParticle(particle_darkness_fx, false)
            ParticleManager:ReleaseParticleIndex(particle_darkness_fx)
        end)
        local particle_moon_fx = ParticleManager:CreateParticle(particle_moon, PATTACH_ABSORIGIN, self:GetCaster())
        ParticleManager:SetParticleControl(particle_moon_fx, 0, Vector(caster_position.x, caster_position.y, caster_position.z + 400))
        Timers:CreateTimer(1.0, function()
            ParticleManager:DestroyParticle(particle_moon_fx, false)
            ParticleManager:ReleaseParticleIndex(particle_moon_fx)
        end)
        self.game_mode = GameRules:GetGameModeEntity()
        GameRules:BeginTemporaryNight(30)
    end
end



--------------
--mirana blessing
---------------
mirana_blessing = class({
    GetAbilityTextureName = function(self)
        return "mirana_blessing"
    end,
    GetIntrinsicModifierName = function(self)
        return "modifier_mirana_blessing"
    end,
})

function mirana_blessing:FindLuna(parent)
    local allies = FindUnitsInRadius(parent:GetTeamNumber(),
            parent:GetAbsOrigin(),
            nil,
            2000,
            DOTA_UNIT_TARGET_TEAM_FRIENDLY,
            DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER,
            false)
    for _, ally in pairs(allies) do
        if IsLuna(ally) == true then
            local Luna = ally
            return Luna
        else return nil
        end
    end
end

modifier_mirana_blessing = class({
    IsDebuff = function(self)
        return false
    end,
    IsHidden = function(self)
        return true
    end,
    IsPurgable = function(self)
        return false
    end,
    RemoveOnDeath = function(self)
        return true
    end,
})

function modifier_mirana_blessing:OnCreated()
    if not IsServer() then
        return
    end
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self:StartIntervalThink(0.5)
end

function modifier_mirana_blessing:OnIntervalThink()
    if not IsServer() then
        return
    end
    self.luna = self.ability:FindLuna(self.parent)
    if self.luna == nil then
        return
    else
        local modifierTable = {}
        modifierTable.ability = self.ability
        modifierTable.target = self.luna
        modifierTable.caster = self.parent
        modifierTable.modifier_name = "modifier_mirana_blessing_buff"
        modifierTable.duration = 5
        GameMode:ApplyBuff(modifierTable)
        modifierTable.ability = self.ability
        modifierTable.target = self.parent
        modifierTable.caster = self.parent
        modifierTable.modifier_name = "modifier_mirana_blessing_buff"
        modifierTable.duration = 5
        GameMode:ApplyBuff(modifierTable)
    end
end

LinkLuaModifier("modifier_mirana_blessing", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)

modifier_mirana_blessing_buff = class({
    IsDebuff = function(self)
        return false
    end,
    IsHidden = function(self)
        return false
    end,
    IsPurgable = function(self)
        return false
    end,
    RemoveOnDeath = function(self)
        return true
    end,
    AllowIllusionDuplicate = function(self)
        return false
    end,
    GetTexture = function(self)
        return mirana_blessing:GetAbilityTextureName()
    end,
    GetEffectName = function(self)
        return "particles/econ/courier/courier_hyeonmu_ambient/courier_hyeonmu_ambient_blue_plus.vpcf"
    end,
    GetEffectAttachType = function(self)
        return PATTACH_OVERHEAD_FOLLOW
    end,

})

function modifier_mirana_blessing_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self.dmg_reduction_final = self.ability:GetSpecialValueFor("dmg_reduction") * 0.01
    self.as_bonus_final = self.ability:GetSpecialValueFor("as_bonus") * 0.01
end

function modifier_mirana_blessing_buff:GetDamageReductionBonus()
    return self.dmg_reduction_final*0.2
end

function modifier_mirana_blessing_buff:GetAttackSpeedPercentBonus()
    return self.as_bonus_final
end

LinkLuaModifier("modifier_mirana_blessing_buff", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)

--------------
--mirana holy
---------------
modifier_mirana_holy = class({
    IsDebuff = function(self)
        return false
    end,
    IsHidden = function(self)
        return true
    end,
    IsPurgable = function(self)
        return false
    end,
    RemoveOnDeath = function(self)
        return true
    end,
    AllowIllusionDuplicate = function(self)
        return false
    end,
})

function modifier_mirana_holy:OnCreated()
    if (not IsServer()) then
        return
    end
    local particle_moon = "particles/units/heroes/hero_mirana/mirana_moonlight_owner.vpcf"
    local caster = self:GetCaster()
    local caster_position = self:GetCaster():GetAbsOrigin()
    local counter = 0
    local number = self:GetAbility():GetSpecialValueFor("number")
    Timers:CreateTimer(0.2, function()
        if counter < number and self ~= nil then
            caster:StartGestureWithPlaybackRate	(ACT_DOTA_ATTACK, 0.85)
            local particle_moon_fx = ParticleManager:CreateParticle(particle_moon, PATTACH_ABSORIGIN, caster)
            ParticleManager:SetParticleControl(particle_moon_fx, 0, Vector(caster_position.x, caster_position.y, caster_position.z + 400))
                Timers:CreateTimer(1.0, function()
                    ParticleManager:DestroyParticle(particle_moon_fx, false)
                    ParticleManager:ReleaseParticleIndex(particle_moon_fx)
                 end)
            counter = counter +1
            return 1
        end
    end)
end

function modifier_mirana_holy:OnDestroy()
    if IsServer() then
        local caster = self:GetCaster()
        caster:RemoveGesture(ACT_DOTA_ATTACK)
    end
end

function modifier_mirana_holy:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true
    }
    return state
end

LinkLuaModifier("modifier_mirana_holy", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)

mirana_holy = class({
    GetAbilityTextureName = function(self)
        return "mirana_holy"
    end,
})

function mirana_holy:IsRequireCastbar()
    return true
end

function mirana_holy:IsInterruptible()
    return false
end

function mirana_holy:OnSpellStart()
    if IsServer() then
        -- Ability properties
        local caster = self:GetCaster()
        local caster_loc = caster:GetAbsOrigin()
        -- Ability specials
        local travel_distance = self:GetSpecialValueFor("range")
        local start_radius = self:GetSpecialValueFor("radius")
        local end_radius = self:GetSpecialValueFor("radius")
        local projectile_speed = self:GetSpecialValueFor("projectile_speed")
        local radius = self:GetSpecialValueFor("range")
        local number = self:GetSpecialValueFor("number")
        local counter = 0
        --root and disarm
        local modifierTable = {}
        modifierTable.ability = self
        modifierTable.target = caster
        modifierTable.caster = caster
        modifierTable.modifier_name = "modifier_mirana_holy"
        modifierTable.duration = number-0.5
        GameMode:ApplyBuff(modifierTable)
        --arrow once every 1 s
        Timers:CreateTimer(0, function()
            --add counter each set of arrows
            if counter < number and caster:HasModifier("modifier_mirana_holy") then
                local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
                        caster:GetAbsOrigin(),
                        nil,
                        radius,
                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                        DOTA_UNIT_TARGET_FLAG_NONE,
                        FIND_ANY_ORDER,
                        false)
                for _, enemy in pairs(enemies) do
                    --particle
                    self.arrow_particle = "particles/econ/items/mirana/mirana_crescent_arrow/mirana_spell_crescent_arrow.vpcf"
                    local enemy_loc = enemy:GetAbsOrigin()
                    local distance = enemy_loc - caster_loc
                    local direction = distance:Normalized()
                    local projectile =
                    {
                        Ability				= self,
                        EffectName			= self.arrow_particle,
                        vSpawnOrigin		= caster:GetAbsOrigin(),
                        fDistance			= travel_distance,
                        fStartRadius		= start_radius,
                        fEndRadius			= end_radius,
                        Source				= caster,
                        bHasFrontalCone		= false,
                        bReplaceExisting	= false,
                        iUnitTargetTeam		= self:GetAbilityTargetTeam(),
                        iUnitTargetFlags	= nil,
                        iUnitTargetType		= self:GetAbilityTargetType(),
                        fExpireTime 		= GameRules:GetGameTime() + 10.0,
                        bDeleteOnHit		= true,
                        vVelocity			= Vector(direction.x,direction.y,0) * projectile_speed,
                        bProvidesVision		= false,
                        --ExtraData			= {damage = damage, stun = stun}
                    }
                    ProjectileManager:CreateLinearProjectile(projectile)
                    -- Play cast sound
                    caster:EmitSound("Hero_Mirana.ArrowCast")
                end
                counter = counter + 1
                return 1
            end
        end)
    end
end

function mirana_holy:OnProjectileHit_ExtraData(target)
    local caster = self:GetCaster()
    local damage = self:GetSpecialValueFor("damage")
    local stun = self:GetSpecialValueFor("stun")
    if target then
        local damageTable = {}
        damageTable.caster = caster
        damageTable.target = target
        damageTable.ability = self
        damageTable.damage = damage*0.001 --nerf
        damageTable.puredmg = true
        GameMode:DamageUnit(damageTable)
        local modifierTable = {}
        modifierTable.ability = self
        modifierTable.target = target
        modifierTable.caster = caster
        modifierTable.modifier_name = "modifier_stunned"
        modifierTable.duration = stun
        GameMode:ApplyDebuff(modifierTable)
    end
end

--------------
--mirana under
---------------
-- modifier
modifier_mirana_under_silence = class({
    IsDebuff = function(self)
        return true
    end,
    IsHidden = function(self)
        return false
    end,
    IsPurgable = function(self)
        return true
    end,
    RemoveOnDeath = function(self)
        return true
    end,
    AllowIllusionDuplicate = function(self)
        return false
    end,
    GetEffectName = function(self)
        return "particles/units/heroes/hero_skywrath_mage/skywrath_mage_ancient_seal_debuff.vpcf"
    end,
    GetEffectAttachType = function(self)
        return PATTACH_OVERHEAD_FOLLOW
    end,
    GetTexture = function(self)
        return mirana_under:GetAbilityTextureName()
    end
})

function modifier_mirana_under_silence:OnCreated()
    if (not IsServer()) then
        return
    end
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
end

function modifier_mirana_under_silence:CheckState()
    local state = { [MODIFIER_STATE_SILENCED] = true, }
    return state
end

LinkLuaModifier("modifier_mirana_under_silence", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)

modifier_mirana_under = class({
    IsDebuff = function(self)
        return true
    end,
    IsHidden = function(self)
        return true
    end,
    IsPurgable = function(self)
        return true
    end,
    RemoveOnDeath = function(self)
        return true
    end,
    AllowIllusionDuplicate = function(self)
        return false
    end,

})

function modifier_mirana_under:OnCreated()
    if (not IsServer()) then
        return
    end
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.caster = self:GetCaster()
    self.interval = self:GetAbility():GetSpecialValueFor("interval") --4
    self.silence = self:GetAbility():GetSpecialValueFor("silence") --3
    --first instance immediately
    local modifierTable = {}
    modifierTable.ability = self.ability
    modifierTable.target = self.parent
    modifierTable.caster = self.caster
    modifierTable.modifier_name = "modifier_mirana_under_silence"
    modifierTable.duration = self.silence
    GameMode:ApplyDebuff(modifierTable)
    local particle_ray = "particles/units/heroes/hero_mirana/mirana_moonlight_ray.vpcf"
    local ray_fx = ParticleManager:CreateParticle(particle_ray, PATTACH_POINT_FOLLOW, self.parent)
    Timers:CreateTimer(3.0, function()
        ParticleManager:DestroyParticle(ray_fx, false)
        ParticleManager:ReleaseParticleIndex(ray_fx)
    end)
    --other instances
    self:StartIntervalThink(self.interval)
end

function modifier_mirana_under:OnIntervalThink()
    if (not IsServer()) then
        return
    end
    local modifierTable = {}
    modifierTable.ability = self.ability
    modifierTable.target = self.parent
    modifierTable.caster = self.caster
    modifierTable.modifier_name = "modifier_mirana_under_silence"
    modifierTable.duration = self.silence
    GameMode:ApplyDebuff(modifierTable)
    local particle_ray = "particles/units/heroes/hero_mirana/mirana_moonlight_ray.vpcf"
    local ray_fx = ParticleManager:CreateParticle(particle_ray, PATTACH_POINT_FOLLOW, self.parent)
    Timers:CreateTimer(3.0, function()
        ParticleManager:DestroyParticle(ray_fx, false)
        ParticleManager:ReleaseParticleIndex(ray_fx)
    end)
end

LinkLuaModifier("modifier_mirana_under", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)

mirana_under = class({
    GetAbilityTextureName = function(self)
        return "mirana_under"
    end,
})

function mirana_under:FindTargetForSilence(caster) --random with already hit removal
    if IsServer() then
        local radius = self:GetSpecialValueFor("range")
        -- Find all nearby enemies
        local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
                caster:GetAbsOrigin(),
                nil,
                3000,
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_HERO,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_ANY_ORDER,
                false)
        local randomEnemy
        for _, enemy in pairs(enemies) do
            if not enemy:HasModifier("modifier_mirana_under") then
                randomEnemy = enemy
                break
            end
        end
        return randomEnemy
    end
end

function mirana_under:Silence(target)
    if (not IsServer()) then
        return
    end
    if (target == nil) then
        return
    end
    local caster = self:GetCaster()
    local modifierTable = {}
    modifierTable.ability = self
    modifierTable.target = target
    modifierTable.caster = caster
    modifierTable.modifier_name = "modifier_mirana_under"
    modifierTable.duration = self.duration
    GameMode:ApplyDebuff(modifierTable)
    target:EmitSound("Hero_SkywrathMage.AncientSeal.Target")
end

function mirana_under:OnSpellStart()
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    local target =  self:FindTargetForSilence(caster)
    self.duration = self:GetSpecialValueFor("seal_duration")
    local number = self:GetSpecialValueFor("number_targets")
    --set table for already hit
    local counter = 0
    Timers:CreateTimer(0, function()
        if counter < number then
            self:Silence(target)
            target = self:FindTargetForSilence(caster)
            counter = counter +1
            return 0.1
        end
    end)
end

--------------
--mirana_aligned
---------------

-- mirana_aligned modifiers
modifier_mirana_aligned_channel = class({
    IsDebuff = function(self)
        return false
    end,
    IsHidden = function(self)
        return true
    end,
    IsPurgable = function(self)
        return false
    end,
    RemoveOnDeath = function(self)
        return true
    end,
    AllowIllusionDuplicate = function(self)
        return false
    end,
})

function modifier_mirana_aligned_channel:OnCreated(keys)
    if not IsServer() then
        return
    end
    self.ability = self:GetAbility()
    if self.ability then
        self.caster = self:GetParent()
        self.channel_time = self.ability:GetSpecialValueFor("channel_time")
        self.tick = self.ability:GetSpecialValueFor("tick")
        self.max_stacks = math.ceil(self.channel_time/ self.tick) --i print have found self.channel_time/ self.tick = 49.999999254942
        --first stack instantly it seems got to 49 if no instant
        local modifierTable = {}
        modifierTable.ability = self.ability
        modifierTable.target = self.caster
        modifierTable.caster = self.caster
        modifierTable.modifier_name = "modifier_mirana_aligned_buff"
        modifierTable.duration = -1 --self.duration
        modifierTable.stacks = 1
        modifierTable.max_stacks = self.max_stacks
        GameMode:ApplyStackingBuff(modifierTable)
        self:StartIntervalThink(self.tick)
    else
        self:Destroy()
    end
end

--gain 1 stack every 0.1s channel total of 50 stacks
function modifier_mirana_aligned_channel:OnIntervalThink()
    if not IsServer() then
        return
    end
    local healFX = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal_blue.vpcf", PATTACH_POINT_FOLLOW, self.caster)
    Timers:CreateTimer(1.0, function()
        ParticleManager:DestroyParticle(healFX, false)
        ParticleManager:ReleaseParticleIndex(healFX)
    end)
    local modifierTable = {}
    modifierTable.ability = self.ability
    modifierTable.target = self.caster
    modifierTable.caster = self.caster
    modifierTable.modifier_name = "modifier_mirana_aligned_buff"
    modifierTable.duration = -1 --self.duration
    modifierTable.stacks = 1
    modifierTable.max_stacks = self.max_stacks-- +1 to make it 50 idk why its 49 from 5/0.1 and still 49 after +1
    GameMode:ApplyStackingBuff(modifierTable)
end

function modifier_mirana_aligned_channel:OnDestroy()
    if IsServer() then
        local caster = self:GetParent()
        caster:RemoveGesture(ACT_DOTA_CAST_ABILITY_1)
    end
end

LinkLuaModifier("modifier_mirana_aligned_channel", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)


modifier_mirana_aligned_buff = class({
    IsDebuff = function(self)
        return false
    end,
    IsHidden = function(self)
        return false
    end,
    IsPurgable = function(self)
        return false
    end,
    RemoveOnDeath = function(self)
        return true
    end,
    AllowIllusionDuplicate = function(self)
        return false
    end,
})

function modifier_mirana_aligned_buff:OnCreated(keys)
    if not IsServer() then
        return
    end
    self.ability = self:GetAbility()
end

function modifier_mirana_aligned_buff:OnRefresh(keys)
    if not IsServer() then
        return
    end
    self:OnCreated()
end

LinkLuaModifier("modifier_mirana_aligned_buff", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)

-- mirana_aligned
mirana_aligned = class({
    GetAbilityTextureName = function(self)
        return "mirana_aligned"
    end,
    GetChannelTime = function(self)
        return self:GetSpecialValueFor("channel_time")
    end
})

function mirana_aligned:IsRequireCastbar()
    return true
end

function mirana_aligned:FindAlignedTarget(caster)
    local radius = self:GetSpecialValueFor("range")
    -- Find all nearby enemies
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
            caster:GetAbsOrigin(),
            nil,
            radius,
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO,
            DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER,
            false)
    local keys = {}
    for k in pairs(enemies) do
        table.insert(keys, k)
    end
    if (#enemies > 0) then
        local AlignedTarget = enemies[keys[math.random(#keys)]] --pick one number = pick one enemy
        if (#enemies > 0) then
            return AlignedTarget
        else
            return nil
        end
    end
end

function mirana_aligned:StarsAlignFX(target)
    local particle_starfall_fx = ParticleManager:CreateParticle("particles/econ/items/mirana/mirana_starstorm_bow/mirana_starstorm_starfall_attack.vpcf",  PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(particle_starfall_fx, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle_starfall_fx, 1, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle_starfall_fx, 3, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle_starfall_fx)
    EmitSoundOn("Hero_Luna.Eclipse.Cast", target)
    Timers:CreateTimer(0.25,function()
        local particle = ParticleManager:CreateParticle("particles/econ/items/wisp/wisp_death_ti7_model.vpcf", PATTACH_WORLDORIGIN, target)
        ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin() + Vector(0,0,0))
        ParticleManager:ReleaseParticleIndex(particle)
    end)
end

function mirana_aligned:OnSpellStart(unit, special_cast)
    if IsServer() then
        local caster = self:GetCaster()
        local caster_position = self:GetCaster():GetAbsOrigin()
        local particle_circle = "particles/units/heroes/hero_mirana/mirana_starfall_circle.vpcf"
        local particle_moon = "particles/units/heroes/hero_mirana/mirana_moonlight_owner.vpcf"
        caster:EmitSound("mirana_mir_attack_05")
        caster.mirana_aligned_modifier = caster:AddNewModifier(caster, self, "modifier_mirana_aligned_channel", { Duration = -1 })
        Timers:CreateTimer(0.2, function()
            if (caster:HasModifier("modifier_mirana_aligned_channel")) then
                caster:StartGestureWithPlaybackRate	(ACT_DOTA_CAST_ABILITY_1, 0.2)
                local particle_moon_fx = ParticleManager:CreateParticle(particle_moon, PATTACH_ABSORIGIN, self:GetCaster())
                ParticleManager:SetParticleControl(particle_moon_fx, 0, Vector(caster_position.x, caster_position.y, caster_position.z + 400))
                local particle_circle_fx = ParticleManager:CreateParticle(particle_circle, PATTACH_ABSORIGIN, self:GetCaster())
                ParticleManager:SetParticleControl(particle_circle_fx, 0, caster_position)
                Timers:CreateTimer(5.0, function()
                    ParticleManager:DestroyParticle(particle_moon_fx, false)
                    ParticleManager:ReleaseParticleIndex(particle_moon_fx)
                    ParticleManager:DestroyParticle(particle_circle_fx, false)
                    ParticleManager:ReleaseParticleIndex(particle_circle_fx)
                end)
                return 5
            end
        end)
    end
end

function mirana_aligned:OnChannelFinish()
    if not IsServer() then
        return
    end
    local caster = self:GetCaster()
    if (caster.mirana_aligned_modifier ~= nil) then
        caster.mirana_aligned_modifier:Destroy()
    end
    --sound star falling
    local target = self:FindAlignedTarget(caster)
    caster:EmitSound("mirana_mir_ability_star_0"..math.random(1,3))
    local expo_power = (caster:FindModifierByName("modifier_mirana_aligned_buff"):GetStackCount())/10
    local expo = self:GetSpecialValueFor("expo")
    local base_damage = self:GetSpecialValueFor("base_damage")
    local damage = base_damage * math.pow(expo, expo_power)
    self:StarsAlignFX(target)
    Timers:CreateTimer(0.25,function()
        local damageTable = {}
        damageTable.caster = caster
        damageTable.target = target
        damageTable.ability = self
        damageTable.damage = damage*0.001 --nerf
        damageTable.naturedmg = true
        damageTable.voiddmg = true
        GameMode:DamageUnit(damageTable)
    end)
    caster:RemoveModifierByName("modifier_mirana_aligned_buff")
end




--------------
--mirana guile
---------------

modifier_mirana_guile = class({
    IsDebuff = function(self)
        return true
    end,
    IsHidden = function(self)
        return false
    end,
    IsPurgable = function(self)
        return false
    end,
    RemoveOnDeath = function(self)
        return true
    end,
    AllowIllusionDuplicate = function(self)
        return false
    end,
    GetEffectName = function(self)
        return "particles/units/npc_boss_mirana/moon_chain_debuff.vpcf"
    end,
    GetEffectAttachType = function(self)
        return PATTACH_ABSORIGIN_FOLLOW
    end
})

function modifier_mirana_guile:OnCreated()
    if (not IsServer()) then
        return
    end
    self.parent = self:GetParent()
    self.caster = self:GetCaster()
end

function modifier_mirana_guile:CheckState()
    local state = {
        [MODIFIER_STATE_ROOTED] = true
    }
    return state
end

LinkLuaModifier("modifier_mirana_guile", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)

mirana_guile = class({
    GetAbilityTextureName = function(self)
        return "mirana_guile"
    end,
})

function  mirana_guile:ApplyChains(target, caster)
    target:EmitSound("Hero_EmberSpirit.SearingChains.Target")
    local impact_pfx = ParticleManager:CreateParticle("particles/units/npc_boss_mirana/moon_chain_cast.vpcf", PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(impact_pfx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(impact_pfx, 1, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(impact_pfx)
    local modifierTable = {}
    modifierTable.caster = caster
    modifierTable.target = target
    modifierTable.ability = self
    modifierTable.modifier_name = "modifier_mirana_guile"
    modifierTable.duration = self.duration
    GameMode:ApplyDebuff(modifierTable)
end

function mirana_guile:FindTargetForRoot(caster) --random with already hit removal
    if IsServer() then
        local radius = self:GetSpecialValueFor("range")
        -- Find all nearby enemies
        local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
                caster:GetAbsOrigin(),
                nil,
                radius,
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_ALL,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_ANY_ORDER,
                false)
        local randomEnemy
        for _, enemy in pairs(enemies) do
            if (not TableContains(self.already_hit, enemy)) then
                randomEnemy = enemy
                break
            end
        end
        return randomEnemy
    end
end

function  mirana_guile:OnSpellStart()
    if (not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    self.duration = self:GetSpecialValueFor("root")
    --root them
    self.already_hit ={}
    self:ApplyChains(target, caster)
    target:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.1})
    target:EmitSound("Hero_VengefulSpirit.NetherSwap")
    table.insert(self.already_hit, target)
    local target2 = self:FindTargetForRoot(caster)
    if target2 == nil then
        return
    else
        self:ApplyChains(target2, caster)
        target2:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.1})
        target2:EmitSound("Hero_VengefulSpirit.NetherSwap")
        local target_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_vengeful/vengeful_nether_swap.vpcf", PATTACH_ABSORIGIN, target)
        ParticleManager:SetParticleControlEnt(target_pfx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(target_pfx, 1, target2, PATTACH_POINT_FOLLOW, "attach_hitloc", target2:GetAbsOrigin(), true)
        local target2_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_vengeful/vengeful_nether_swap_target.vpcf", PATTACH_ABSORIGIN, target2)
        ParticleManager:SetParticleControlEnt(target2_pfx, 0, target2, PATTACH_POINT_FOLLOW, "attach_hitloc", target2:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(target2_pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
        --swap position
        local target_loc = target:GetAbsOrigin()
        local target2_loc = target2:GetAbsOrigin()
        FindClearSpaceForUnit(target, target2_loc, true)
        FindClearSpaceForUnit(target2, target_loc, true)
        --local tree_radius = self:GetSpecialValueFor("tree_radius") --200
        -- Destroy trees around start and end areas -- ill leave it here just incase ppl get struck
        --GridNav:DestroyTreesAroundPoint(caster_loc, tree_radius, false)
        --GridNav:DestroyTreesAroundPoint(target_loc, tree_radius, false)
        --swap aggro
        local high_aggro = Aggro:Get(target, caster)
        local random_aggro = Aggro:Get(target2, caster)
        Aggro:Reset(caster)
        Aggro:Add(target, caster, random_aggro)
        Aggro:Add(target2, caster, high_aggro)
    end
end

--------------
--mirana bound
---------------
mirana_bound = class({
    GetAbilityTextureName = function(self)
        return "mirana_bound"
    end,
    GetIntrinsicModifierName = function(self)
        return "modifier_mirana_bound"
    end,
})

modifier_mirana_bound = class({
    IsDebuff = function(self)
        return false
    end,
    IsHidden = function(self)
        return true
    end,
    IsPurgable = function(self)
        return false
    end,
    RemoveOnDeath = function(self)
        return true
    end,
    AllowIllusionDuplicate = function(self)
        return false
    end,
    DeclareFunctions = function(self)
        return { MODIFIER_EVENT_ON_DEATH }
    end
})

function modifier_mirana_bound:OnCreated()
    if not IsServer() then
        return
    end
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    --apply buff to mirana but set inactive state
    local modifierTable = {}
    modifierTable.ability = self.ability
    modifierTable.target = self.parent
    modifierTable.caster = self.parent
    modifierTable.modifier_name = "modifier_mirana_bound_buff"
    modifierTable.duration = -1
    modifierTable.stacks = 1
    modifierTable.max_stacks = 2
    GameMode:ApplyStackingBuff(modifierTable)
    self.luna = nil
    Timers:CreateTimer(0, function()
        if self.luna == nil then
            self.luna = self.ability:FindLuna(self.parent)
            return 0.1
        end
    end)
end

function mirana_bound:FindLuna(parent)
    local allies = FindUnitsInRadius(parent:GetTeamNumber(),
            parent:GetAbsOrigin(),
            nil,
            25000,
            DOTA_UNIT_TARGET_TEAM_FRIENDLY,
            DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER,
            false)
    for _, ally in pairs(allies) do
        if IsLuna(ally) == true then
            local Luna = ally
            return Luna
        else return nil
        end
    end
end

function modifier_mirana_bound:OnDeath(params)
    if (params.unit == self.parent) then
        if self.luna ~= nil then
        self.luna:FindModifierByName("modifier_luna_bound_buff"):SetStackCount(2)
        end
    end
end

LinkLuaModifier("modifier_mirana_bound", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)

modifier_mirana_bound_buff = class({
    IsDebuff = function(self)
        return false
    end,
    IsHidden = function(self)
        return false
    end,
    IsPurgable = function(self)
        return false
    end,
    RemoveOnDeath = function(self)
        return false
    end,
    AllowIllusionDuplicate = function(self)
        return false
    end,
    GetTexture = function(self)
        return mirana_bound:GetAbilityTextureName()
    end,
})

function modifier_mirana_bound_buff:OnCreated()
    if not IsServer() then
        return
    end
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.active = false
    self.ad_bonus = self:GetAbility():GetSpecialValueFor("ad_bonus")*0.01
    self.lifesteal = self:GetAbility():GetSpecialValueFor("lifesteal")
end

function modifier_mirana_bound_buff:GetAttackDamagePercentBonus()
    if self:GetStackCount() == 2 then
    return self.ad_bonus
    else return 0
    end
end

---@param damageTable DAMAGE_TABLE
function modifier_mirana_bound_buff:OnTakeDamage(damageTable)
    local modifier = damageTable.attacker:FindModifierByName("modifier_mirana_bound_buff")
    local stack = 1
    if modifier ~= nil then
        stack = modifier:GetStackCount()
    end
    if (damageTable.damage > 0 and stack >1 and not damageTable.ability and damageTable.physdmg ) then
    local healFX = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_POINT_FOLLOW, damageTable.attacker)
    Timers:CreateTimer(1.0, function()
    ParticleManager:DestroyParticle(healFX, false)
    ParticleManager:ReleaseParticleIndex(healFX)
    end)
    local healTable = {}
    healTable.caster = damageTable.attacker
    healTable.target = damageTable.attacker
    healTable.ability = modifier:GetAbility()
    healTable.heal = damageTable.damage * modifier:GetAbility():GetSpecialValueFor("lifesteal") * 0.01
    GameMode:HealUnit(healTable)
    end
end

LinkLuaModifier("modifier_mirana_bound_buff", "creeps/zone1/boss/mirana.lua", LUA_MODIFIER_MOTION_NONE)

--internal stuff
if (IsServer() and not GameMode.ZONE1_BOSS_MIRANA) then
    GameMode:RegisterPreDamageEventHandler(Dynamic_Wrap(modifier_mirana_bound_buff, 'OnTakeDamage'))
    GameMode.ZONE1_BOSS_MIRANA = true
end