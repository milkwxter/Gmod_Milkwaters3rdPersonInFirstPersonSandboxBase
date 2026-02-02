if SERVER then
	AddCSLuaFile()
    game.AddParticles("particles/invasion_ray_gun_fx.pcf")
    PrecacheParticleSystem("muzzle_raygun_red")
end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "C.A.P.P.E.R"
SWEP.Purpose = "A standard pistol."
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Scout" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_capper.png"

SWEP.WorldModel = "models/workshop/weapons/c_models/c_invasion_pistol/c_invasion_pistol.mdl"

SWEP.HandOffset_Pos = Vector(5, -1, 1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, -1, 4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_raygun_red"

SWEP.SoundShootPrimary = "weapons/capper_shoot.wav"
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

SWEP.TracerName = "milkwater_tracer_laser"