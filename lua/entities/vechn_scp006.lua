AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "SCP-006"
ENT.Category = "Vechniy SCP"
ENT.Author = "VechniyRabotnik"
ENT.Spawnable = true

local HEAL_AMOUNT    = 10
local HEAL_INTERVAL  = 1
local SOUND_INTERVAL = 3
local EFFECT_COUNT   = 6
local EFFECT_NAME    = "watersplash"
local SOUND_NAME     = "ambient/water/water_flow_loop1.wav"
local SOUND_LEVEL    = 60  
local SOUND_PITCH    = 100

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/thekins/water/water_moving_03.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetSkin(2)
        self:SetModelScale(0.3, 0)

        local phys = self:GetPhysicsObject()
        if phys and phys:IsValid() then phys:Wake() end

        self.IsActive = true

        timer.Create("SCP006_Healing_" .. self:EntIndex(), HEAL_INTERVAL, 0, function()
            if not IsValid(self) then return end
            self:HealPlayersInRange()
            self:SpawnEffects()
        end)

        timer.Create("SCP006_Sound_" .. self:EntIndex(), SOUND_INTERVAL, 0, function()
            if not IsValid(self) then return end
            sound.Play(SOUND_NAME, self:GetPos(), SOUND_LEVEL, SOUND_PITCH)
        end)
    end

    function ENT:SpawnEffects()
    
        local mins, maxs = self:OBBMins(), self:OBBMaxs()
        for i = 1, EFFECT_COUNT do
            local localpos = Vector(
                math.Rand(mins.x, maxs.x),
                math.Rand(mins.y, maxs.y),
                math.Rand(mins.z, maxs.z)
            )
            local worldpos = self:LocalToWorld(localpos) + Vector(0, 0, 5)
            local ed = EffectData()
            ed:SetOrigin(worldpos)
            util.Effect(EFFECT_NAME, ed, true, true)
        end
    end

    function ENT:HealPlayersInRange()
        local radius = 200
        local entsInSphere = ents.FindInSphere(self:GetPos(), radius)

        for _, ply in ipairs(entsInSphere) do
            if ply:IsPlayer() and ply:Alive() then
                local maxHealth = ply:GetMaxHealth() or 100
                if ply:Health() < maxHealth then
                    ply:SetHealth(math.min(maxHealth, ply:Health() + HEAL_AMOUNT))
                end

                if ply:IsOnFire() then
                    ply:Extinguish()
                end

                local poisonedKeysBool = {"Poisoned", "poisoned", "isPoisoned"}
                local poisonedKeysInt  = {"PoisonLevel", "poison_level", "poison"}

                for _, k in ipairs(poisonedKeysBool) do
                    if ply:GetNWBool(k, false) then
                        ply:SetNWBool(k, false)
                    end
                end
                for _, k in ipairs(poisonedKeysInt) do
                    if ply:GetNWInt(k, 0) > 0 then
                        ply:SetNWInt(k, 0)
                    end
                end

              
                if ply.CurePoison then pcall(ply.CurePoison, ply) end
                if ply.ClearPoison then pcall(ply.ClearPoison, ply) end
                if ply.RemovePoison then pcall(ply.RemovePoison, ply) end

                
                local sid = ply:SteamID()
                timer.Remove("PoisonTimer_" .. sid)
                timer.Remove("poison_timer_" .. sid)
                timer.Remove("poison_" .. sid)

            end
        end
    end

    function ENT:OnRemove()
        timer.Remove("SCP006_Healing_" .. self:EntIndex())
        timer.Remove("SCP006_Sound_" .. self:EntIndex())
    end
end

if CLIENT then
 
    function ENT:Draw()
        self:DrawModel()

        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = self:GetPos() + Vector(0, 0, 10)
            dlight.r = 100
            dlight.g = 180
            dlight.b = 255
            dlight.brightness = 2
            dlight.Decay = 500
            dlight.Size = 200
            dlight.DieTime = CurTime() + 1
        end
    end
end
