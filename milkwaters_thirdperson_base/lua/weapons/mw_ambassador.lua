if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Ambassador"
SWEP.Purpose = "Headshot for critical damage."
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_ambassador.png"

SWEP.WorldModel = "models/weapons/c_models/c_ambassador/c_ambassador.mdl"

SWEP.HandOffset_Pos = Vector(4, -1.5, -2) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, -1, 4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "MuzzleEffect"

SWEP.SoundShootPrimary = "weapons/ambassador_shoot.wav"
SWEP.HoldType = "revolver"
SWEP.Caseless = true

SWEP.Primary.ClipSize = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.6
SWEP.Primary.Damage = 34
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.02
SWEP.Primary.Recoil = 6

-- mini crits if you got a head shot
function SWEP:ModifyDamage(att, tr, dmginfo)
    -- get base damage + base crits
    local dmg, isMiniCrit, isFullCrit = self.BaseClass.ModifyDamage(self, att, tr, dmginfo)

    local hit = tr.Entity
    if not IsValid(hit) then
        return dmg, isMiniCrit, isFullCrit
    end

    -- headshot
	if tr.HitGroup == HITGROUP_HEAD and (hit:IsNPC() or hit:IsPlayer()) then
		isFullCrit = true
	end

    return dmg, isMiniCrit, isFullCrit
end