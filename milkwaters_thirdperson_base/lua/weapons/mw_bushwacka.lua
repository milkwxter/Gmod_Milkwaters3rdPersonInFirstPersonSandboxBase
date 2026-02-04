if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Bushwacka"
SWEP.Purpose = "Minicrits turn into full crits!"
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Sniper" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_bushwacka.png"

SWEP.WorldModel = "models/weapons/c_models/c_croc_knife/c_croc_knife.mdl"

SWEP.HandOffset_Pos = Vector(3, -1, -3) -- forward, right, up
SWEP.HandOffset_Ang = Angle(90, 180, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(0, 0, 0) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = ""

SWEP.SoundShootPrimary = ""
SWEP.HoldType = "melee"
SWEP.Casing = ""

SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Ammo = "none"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.5
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 1
SWEP.Cone = 0
SWEP.Primary.Recoil = 1

SWEP.Melee = true
SWEP.MeleeDamage = 35
SWEP.MeleeRange = 70
SWEP.MeleeDelay = 0.2

-- damage vulnerability
hook.Add("EntityTakeDamage", "MW_BushwackaDamagePenalty", function(target, dmginfo)
    if not IsValid(target) or not target:IsPlayer() then return end

    local wep = target:GetActiveWeapon()
    if not IsValid(wep) then return end

    if wep:GetClass() == "mw_bushwacka" then
        dmginfo:ScaleDamage(1.2)
    end
end)

-- full crits if you got a mini crit
function SWEP:ModifyDamage(att, tr, dmginfo)
    -- get base damage + base crits
    local dmg, isMiniCrit, isFullCrit = self.BaseClass.ModifyDamage(self, att, tr, dmginfo)

    local hit = tr.Entity
    if not IsValid(hit) then
        return dmg, isMiniCrit, isFullCrit
    end

    if isMiniCrit then
		isFullCrit = true
	end

    return dmg, isMiniCrit, isFullCrit
end