if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tf2milkbase"

SWEP.PrintName = "Shotgun"
SWEP.Purpose = "A standard shotgun."
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Soldier", "Heavy", "Pyro", "Engineer" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mb_shotgun.png"

SWEP.ViewModel = "models/v_shotgun_engineer.mdl"
SWEP.WorldModel = "models/weapons/c_models/c_shotgun/c_shotgun.mdl"

SWEP.HandOffset_Pos = Vector(0, 0, 0) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(40, 6, -5) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_shotgun"

SWEP.SoundShootPrimary = "weapons/shotgun_shoot.wav"
SWEP.HoldType = "shotgun"
SWEP.Casing = "ShotgunShellEject"

SWEP.Primary.ClipSize = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Ammo = "Buckshot"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.625
SWEP.Primary.Damage = 6
SWEP.Primary.NumShots = 10
SWEP.Cone = 0.1
SWEP.Primary.Recoil = 6