if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Scattergun"
SWEP.Purpose = "A standard shotgun."
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Scout" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_scattergun.png"

SWEP.WorldModel = "models/weapons/c_models/c_scattergun.mdl"

SWEP.HandOffset_Pos = Vector(6, -1, -2) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, 0, 5) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_shotgun"

SWEP.SoundShootPrimary = "weapons/scatter_gun_shoot.wav"
SWEP.HoldType = "shotgun"
SWEP.Casing = "ShotgunShellEject"

SWEP.Primary.ClipSize = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.625
SWEP.Primary.Damage = 6
SWEP.Primary.NumShots = 10
SWEP.Cone = 0.1
SWEP.Primary.Recoil = 6