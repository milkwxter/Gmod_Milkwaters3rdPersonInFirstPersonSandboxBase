if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tf2milkbase"

SWEP.PrintName = "Assault Rifle"
SWEP.Purpose = "A standard automatic rifle."
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Soldier" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mb_assault_rifle.png"

SWEP.ViewModel = "models/v_assault_rifle.mdl"
SWEP.WorldModel = "models/weapons/c_models/c_assault_rifle/c_assault_rifle.mdl"

SWEP.HandOffset_Pos = Vector(5, -1, 1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(40, -9, -4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_smg"

SWEP.SoundShootPrimary = "weapons/assaultrifle_shoot.wav"
SWEP.HoldType = "ar2"
SWEP.Casing = "ShellEject"

SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Ammo = "SMG1"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.12
SWEP.Primary.Damage = 10
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.04
SWEP.Primary.Recoil = 1