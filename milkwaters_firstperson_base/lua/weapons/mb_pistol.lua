if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tf2milkbase"

SWEP.PrintName = "Pistol"
SWEP.Purpose = "A standard pistol."
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Scout", "Engineer" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mb_pistol.png"

SWEP.ViewModel = "models/v_pistol_engineer.mdl"
SWEP.WorldModel = "models/weapons/c_models/c_pistol/c_pistol.mdl"

SWEP.HandOffset_Pos = Vector(5, -1, 1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(40, -9, -4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_smg"

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