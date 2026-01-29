if SERVER then AddCSLuaFile() end

SWEP.Base = "milkwaters_3p_base"

SWEP.PrintName = "Winger"
SWEP.Purpose = "Jump higher."
SWEP.Category = "Milkwater"
SWEP.Spawnable = true
SWEP.IconOverride = "weapons/mw_winger.png"

SWEP.WorldModel = "models/weapons/c_models/c_winger_pistol/c_winger_pistol.mdl"

SWEP.HandOffset_Pos = Vector(5, -1, 1) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 180) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(20, -1, 4) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_smg"

SWEP.SoundShootPrimary = "weapons/winger_shoot.wav"
SWEP.HoldType = "pistol"
SWEP.Casing = "ShellEject"

SWEP.Primary.ClipSize = 5
SWEP.Primary.DefaultClip = 5
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = true
SWEP.Primary.FireDelay = 0.15
SWEP.Primary.Damage = 17
SWEP.Primary.NumShots = 1
SWEP.Cone = 0.02
SWEP.Primary.Recoil = 1

-- jump booster
local JumpBoost = 1.25
function SWEP:Deploy()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- store original jump power
    if not owner._WingerOriginalJump then
        owner._WingerOriginalJump = owner:GetJumpPower()
    end

    owner:SetJumpPower(owner._WingerOriginalJump * JumpBoost)
	
	-- base runs
	self.BaseClass.Deploy(self)
end

function SWEP:Holster()
    local owner = self:GetOwner()
    if IsValid(owner) and owner._WingerOriginalJump then
        owner:SetJumpPower(owner._WingerOriginalJump)
    end
    return true
end

function SWEP:OnRemove()
    local owner = self:GetOwner()
    if IsValid(owner) and owner._WingerOriginalJump then
        owner:SetJumpPower(owner._WingerOriginalJump)
    end
end
