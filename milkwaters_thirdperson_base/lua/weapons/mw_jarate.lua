if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Jarate"
SWEP.Purpose = "Coat targets in piss for mini-crits!"
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_jarate.png"

SWEP.WorldModel = "models/weapons/c_models/urinejar.mdl"

SWEP.HandOffset_Pos = Vector(4, -3, 0) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, -1, 4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = ""

SWEP.SoundShootPrimary = "weapons/jar_single.wav"
SWEP.HoldType = "grenade"
SWEP.Caseless = true

SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Ammo = "Pistol"

SWEP.Projectile = true
SWEP.ProjectileClass = "mw_jarate_proj"
SWEP.ProjectileSpeed = 600
SWEP.ProjectileGravity = true

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.1
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.05
SWEP.Primary.Recoil = 1