if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Screaming Eagle"
SWEP.Purpose = "A standard LMG."
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_screaming_eagle.png"

SWEP.WorldModel = "models/weapons/lmg/w_lmg.mdl"

SWEP.HandOffset_Pos = Vector(17, -1, -3) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(25, 0, 3) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_smg"

SWEP.SoundShootPrimary = "weapons/screaming_eagle_shoot.wav"
SWEP.HoldType = "crossbow"
SWEP.Casing = "ShellEject"

SWEP.Primary.ClipSize = 50
SWEP.Primary.DefaultClip = 50
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.1
SWEP.Primary.Damage = 11
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.05
SWEP.Primary.Recoil = 4