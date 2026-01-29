if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Rocket Jumper"
SWEP.Purpose = "A rocket launcher that deals no damage."
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_rocket_jumper.png"

SWEP.WorldModel = "models/weapons/c_models/c_rocketjumper/c_rocketjumper.mdl"

SWEP.HandOffset_Pos = Vector(4, -1, -3) -- forward, right, up
SWEP.HandOffset_Ang = Angle(10, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(0, 0, 7) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = ""

SWEP.SoundShootPrimary = "weapons/rocket_jumper_shoot.wav"
SWEP.HoldType = "rpg"
SWEP.Caseless = true

SWEP.Primary.ClipSize = 4
SWEP.Primary.DefaultClip = 4
SWEP.Primary.Ammo = "Pistol"

SWEP.Projectile = true
SWEP.ProjectileClass = "mw_rocket_jumper_proj"
SWEP.ProjectileSpeed = 1100
SWEP.ProjectileGravity = false

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.8
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.05
SWEP.Primary.Recoil = 1