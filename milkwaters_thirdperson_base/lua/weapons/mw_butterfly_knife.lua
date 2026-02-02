if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Butterfly Knife"
SWEP.Purpose = "Backstab for crits!"
SWEP.Category = "Milkwater"
SWEP.SubCatType = { "Spy" }
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_butterfly_knife.png"

SWEP.WorldModel = "models/weapons/c_models/c_knife/c_knife.mdl"

SWEP.HandOffset_Pos = Vector(3, -1, -2) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, -1, 4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = ""

SWEP.SoundShootPrimary = ""
SWEP.HoldType = "knife"
SWEP.Casing = ""

SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Ammo = "none"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.8
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 1
SWEP.Cone = 0
SWEP.Primary.Recoil = 1

SWEP.Melee = true
SWEP.MeleeDamage = 40
SWEP.MeleeRange = 70
SWEP.MeleeDelay = 0.2

-- full crits if you got a back stab
function SWEP:ModifyDamage(att, tr, dmginfo)
    -- get base damage + base crits
    local dmg, isMiniCrit, isFullCrit = self.BaseClass.ModifyDamage(self, att, tr, dmginfo)

    local hit = tr.Entity
    if not IsValid(hit) then
        return dmg, isMiniCrit, isFullCrit
    end

    if hit:IsPlayer() or hit:IsNPC() then
		local attackerForward = att:GetAimVector()
		local victimForward = hit:GetAimVector()
		-- dot > 0.5 means attacker is behind victim and facing same direction
		local dot = attackerForward:Dot(victimForward)
		if dot > 0.5 then
			isFullCrit = true
			dmg = 150
		end
	end

    return dmg, isMiniCrit, isFullCrit
end