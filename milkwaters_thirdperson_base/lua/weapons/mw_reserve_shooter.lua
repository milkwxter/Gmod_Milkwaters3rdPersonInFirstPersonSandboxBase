if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Reserve Shooter"
SWEP.Purpose = "Shoot airborne targets to mini-crit them."
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_reserve_shooter.png"

SWEP.WorldModel = "models/workshop/weapons/c_models/c_reserve_shooter/c_reserve_shooter.mdl"

SWEP.HandOffset_Pos = Vector(1, -1, -1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(40, 0, 5) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "MuzzleEffect"

SWEP.SoundShootPrimary = "weapons/reserve_shooter_02.wav"
SWEP.HoldType = "shotgun"
SWEP.Casing = "ShotgunShellEject"

SWEP.Primary.ClipSize = 4
SWEP.Primary.DefaultClip = 4
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = false
SWEP.Primary.FireDelay = 0.625
SWEP.Primary.Damage = 6
SWEP.Primary.NumShots = 10
SWEP.Cone = 0.1
SWEP.Primary.Recoil = 5

-- more damage if your victim is in the air
function SWEP:ModifyDamage(att, tr, dmginfo)
    local hit = tr.Entity
    if not IsValid(hit) then
        return dmginfo:GetDamage()
    end

    local dmg = dmginfo:GetDamage()
	local isMiniCrit = false

    -- airborne minicrit
    if not hit:IsOnGround() then
		isMiniCrit = true
    end

    return dmg, isMiniCrit
end
