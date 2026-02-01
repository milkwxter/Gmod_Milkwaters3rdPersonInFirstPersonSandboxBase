if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Spitfire"
SWEP.Purpose = "Shoot flaming targets to mini-crit them."
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_spitfire.png"

SWEP.WorldModel = "models/weapons/spitfire/w_spitfire.mdl"

SWEP.HandOffset_Pos = Vector(1, -1, -1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(40, 0, 5) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_shotgun"

SWEP.SoundShootPrimary = "weapons/spitfire_shoot.wav"
SWEP.HoldType = "shotgun"
SWEP.Casing = "ShotgunShellEject"

SWEP.Primary.ClipSize = 3
SWEP.Primary.DefaultClip = 3
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.78125
SWEP.Primary.Damage = 4.5
SWEP.Primary.NumShots = 10
SWEP.Cone = 0.1
SWEP.Primary.Recoil = 5

-- mini crits if your victim is in ON FIRE!!!!!!!!!
function SWEP:ModifyDamage(att, tr, dmginfo)
    -- get base damage + base crits
    local dmg, isMiniCrit, isFullCrit = self.BaseClass.ModifyDamage(self, att, tr, dmginfo)

    local hit = tr.Entity
    if not IsValid(hit) then
        return dmg, isMiniCrit, isFullCrit
    end

    -- flaming targets get minicrit
    if hit:IsOnFire() then
        isMiniCrit = true
    end

    return dmg, isMiniCrit, isFullCrit
end