if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Flare Gun"
SWEP.Purpose = "A standard flare gun."
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_flare_gun.png"

SWEP.WorldModel = "models/weapons/c_models/c_flaregun_pyro/c_flaregun_pyro.mdl"

SWEP.HandOffset_Pos = Vector(3, -1, -1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(0, 0, 7) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = ""

SWEP.SoundShootPrimary = "weapons/flaregun_shoot.wav"
SWEP.HoldType = "pistol"
SWEP.Caseless = true

SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Ammo = "Pistol"

SWEP.Projectile = true
SWEP.ProjectileClass = "mw_flare_proj"
SWEP.ProjectileSpeed = 2000
SWEP.ProjectileGravity = true

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.8
SWEP.Primary.Damage = 30
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.1
SWEP.Primary.Recoil = 1