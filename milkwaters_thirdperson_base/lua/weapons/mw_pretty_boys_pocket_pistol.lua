if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Pretty Boy's Pocket Pistol"
SWEP.Purpose = "Heals you when landing a shot."
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Scout" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_pretty_boys_pocket_pistol.png"

SWEP.WorldModel = "models/weapons/c_models/c_pep_pistol/c_pep_pistol.mdl"

SWEP.HandOffset_Pos = Vector(5, -1, 1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(4, -3, 4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_smg"

SWEP.SoundShootPrimary = "weapons/doom_scout_pistol.wav"
SWEP.HoldType = "pistol"
SWEP.Casing = "ShellEject"

SWEP.Primary.ClipSize = 9
SWEP.Primary.DefaultClip = 9
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.135
SWEP.Primary.Damage = 15
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.03
SWEP.Primary.Recoil = 1

function SWEP:ExtraEffectOnHit(att, tr)
	-- hello
	local hp = att:Health() + 3
	hp = math.min(hp, att:GetMaxHealth())
	att:SetHealth(hp)
end