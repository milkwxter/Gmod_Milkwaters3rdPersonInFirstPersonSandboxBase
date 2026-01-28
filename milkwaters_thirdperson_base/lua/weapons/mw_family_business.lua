if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Family Business"
SWEP.Purpose = "A fast firing shotgun with a large magazine."
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_family_business.png"

SWEP.WorldModel = "models/weapons/c_models/c_russian_riot/c_russian_riot.mdl"

SWEP.HandOffset_Pos = Vector(1, -1, -1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(40, 0, 5) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "MuzzleEffect"

SWEP.SoundShootPrimary = "weapons/family_business_shoot.wav"
SWEP.HoldType = "shotgun"
SWEP.Casing = "ShotgunShellEject"

SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.531
SWEP.Primary.Damage = 5.1
SWEP.Primary.NumShots = 10
SWEP.Cone = 0.1
SWEP.Primary.Recoil = 5