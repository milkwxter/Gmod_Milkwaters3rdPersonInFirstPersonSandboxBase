if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Ullapool Caber"
SWEP.Purpose = "An explosive melee weapon. Be careful!"
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Demoman" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_ullapool_caber.png"

SWEP.WorldModel = "models/workshop/weapons/c_models/c_caber/c_caber.mdl"

SWEP.HandOffset_Pos = Vector(3, -1, -1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, -1, 4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = ""

SWEP.SoundShootPrimary = ""
SWEP.HoldType = "melee"
SWEP.Casing = ""

SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Ammo = "none"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.96
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 1
SWEP.Cone = 0
SWEP.Primary.Recoil = 1

SWEP.Melee = true
SWEP.MeleeDamage = 55
SWEP.MeleeRange = 70
SWEP.MeleeDelay = 0.2

local WorldModelAlt = "models/workshop/weapons/c_models/c_caber/c_caber_exploded.mdl"

function SWEP:ExtraEffectOnHit(att, tr)
    if SERVER then
        -- swap model
        local mdl = self.GetCurrentWorldModel and self:GetCurrentWorldModel() or self.WorldModel
        if mdl == WorldModelAlt then return end
        self:SetCurrentWorldModel(WorldModelAlt)

        -- explosion
        local pos = tr.HitPos
        local dmg = 75
        local radius = 250
        util.BlastDamage(self, att, pos, radius, dmg)

        -- explosion effect
        local ed = EffectData()
        ed:SetOrigin(pos)
        ed:SetMagnitude(1)
        ed:SetScale(1)
        ed:SetRadius(radius)
        util.Effect("Explosion", ed, true, true)

        -- screen shake
        util.ScreenShake(pos, 25, 150, 1, 600)
    end
end
