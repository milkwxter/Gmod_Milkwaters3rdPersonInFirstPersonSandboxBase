if SERVER then AddCSLuaFile() end

if CLIENT then
    game.AddParticles("particles/flamethrower.pcf")
    PrecacheParticleSystem("flamethrower_rainbow")
end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Rainblower"
SWEP.Purpose = "A standard rainblower. Wait what?"
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_rainblower.png"

SWEP.WorldModel = "models/weapons/c_models/c_rainblower/c_rainblower.mdl"
SWEP.PlayAttackAnim = false

SWEP.HandOffset_Pos = Vector(0, 0, 0) -- forward, right, up
SWEP.HandOffset_Ang = Angle(10, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(70, 0, 1) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffectStaysWhileFiring = true
SWEP.MuzzleEffect = "flamethrower_rainbow"

SWEP.LoopShootingSound = true
SWEP.SoundShootPrimary = "weapons/rainblower/rainblower_start.wav"
SWEP.SoundShootLoop = "weapons/rainblower/rainblower_loop.wav"
SWEP.SoundShootEnd = "weapons/rainblower/rainblower_end.wav"

SWEP.HoldType = "crossbow"
SWEP.Caseless = true

SWEP.Primary.ClipSize = 200
SWEP.Primary.DefaultClip = 200
SWEP.Primary.Ammo = "Pistol"

SWEP.Projectile = true
SWEP.ProjectileClass = "mw_fire_proj"
SWEP.ProjectileSpeed = 1100
SWEP.ProjectileGravity = false

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.03
SWEP.Primary.Damage = 7
SWEP.Primary.NumShots = 1
SWEP.Cone = 3
SWEP.Primary.Recoil = 0

SWEP.EnablePyroland = true
