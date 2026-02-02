if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Force-a-Nature"
SWEP.Purpose = "Knockback scattergun!"
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Scout" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_force_a_nature.png"

SWEP.WorldModel = "models/weapons/c_models/c_double_barrel.mdl"

SWEP.HandOffset_Pos = Vector(6, -1, -2) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, 0, 5) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_shotgun"

SWEP.SoundShootPrimary = "weapons/scatter_gun_double_shoot.wav"
SWEP.HoldType = "shotgun"
SWEP.Casing = "ShotgunShellEject"

SWEP.Primary.ClipSize = 2
SWEP.Primary.DefaultClip = 2
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.3125
SWEP.Primary.Damage = 5.4
SWEP.Primary.NumShots = 12
SWEP.Cone = 0.15
SWEP.Primary.Recoil = 12

function SWEP:ExtraEffectOnShoot()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- return if grounded
    if owner:OnGround() then return end

    -- knockback
    local dir = -owner:EyeAngles():Forward()
    local force = 300
    owner:SetVelocity(dir * force)
end

function SWEP:ExtraEffectOnHit(att, tr)
	-- hello
	local victim = tr.Entity
	if not IsValid(victim) then return end
	local dir = att:EyeAngles():Forward()
    local force = 300
    victim:SetVelocity(dir * force)
end