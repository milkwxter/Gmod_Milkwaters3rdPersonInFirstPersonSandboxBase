if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Syringe Gun"
SWEP.Purpose = "A projectile weapon with no special abilities."
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_syringe_gun.png"

SWEP.WorldModel = "models/weapons/c_models/c_syringegun/c_syringegun.mdl"

SWEP.HandOffset_Pos = Vector(10, -1, 1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, -1, 4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "MuzzleEffect"

SWEP.SoundShootPrimary = "weapons/syringegun_shoot.wav"
SWEP.HoldType = "pistol"
SWEP.Caseless = true

SWEP.Primary.ClipSize = 40
SWEP.Primary.DefaultClip = 40
SWEP.Primary.Ammo = "Pistol"

SWEP.Projectile = true
SWEP.ProjectileClass = "mw_syringe"
SWEP.ProjectileSpeed = 990
SWEP.ProjectileGravity = true

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.105
SWEP.Primary.Damage = 10
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.01
SWEP.Primary.Recoil = 1