if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Grenade Launcher"
SWEP.Purpose = "A standard grenade launcher."
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Demoman" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_grenade_launcher.png"

SWEP.WorldModel = "models/weapons/c_models/c_grenadelauncher/c_grenadelauncher.mdl"

SWEP.HandOffset_Pos = Vector(4, -3, 0) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, -1, 4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = ""

SWEP.SoundShootPrimary = "weapons/grenade_launcher_shoot.wav"
SWEP.HoldType = "crossbow"
SWEP.Caseless = true

SWEP.Primary.ClipSize = 4
SWEP.Primary.DefaultClip = 4
SWEP.Primary.Ammo = "Pistol"

SWEP.Projectile = true
SWEP.ProjectileClass = "mw_pipebomb_proj"
SWEP.ProjectileSpeed = 1216
SWEP.ProjectileGravity = true

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.6
SWEP.Primary.Damage = 100
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.05
SWEP.Primary.Recoil = 1