if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Pistol"
SWEP.Purpose = "A standard pistol."
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_pistol.png"

SWEP.WorldModel = "models/weapons/c_models/c_pistol/c_pistol.mdl"

SWEP.HandOffset_Pos = Vector(5, -1, 1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, -1, 4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "MuzzleEffect"

SWEP.SoundShootPrimary = "weapons/pistol_shoot.wav"
SWEP.HoldType = "pistol"
SWEP.Casing = "ShellEject"

SWEP.Primary.ClipSize = 12
SWEP.Primary.DefaultClip = 12
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.15
SWEP.Primary.Damage = 15
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.02
SWEP.Primary.Recoil = 1