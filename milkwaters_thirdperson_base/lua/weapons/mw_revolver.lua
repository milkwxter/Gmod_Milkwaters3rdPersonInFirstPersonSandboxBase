if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Revolver"
SWEP.Purpose = "A standard revolver."
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Spy" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_revolver.png"

SWEP.WorldModel = "models/weapons/c_models/c_revolver/c_revolver.mdl"

SWEP.HandOffset_Pos = Vector(4, -1.5, -2) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, -1, 4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_smg"

SWEP.SoundShootPrimary = "weapons/revolver_shoot.wav"
SWEP.HoldType = "revolver"
SWEP.Caseless = true

SWEP.Primary.ClipSize = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.5
SWEP.Primary.Damage = 40
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.02
SWEP.Primary.Recoil = 5