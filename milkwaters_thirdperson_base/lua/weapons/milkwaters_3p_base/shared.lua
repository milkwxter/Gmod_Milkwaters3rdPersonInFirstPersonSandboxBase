-- shared.lua
if SERVER then
	-- add my files
	AddCSLuaFile()
	AddCSLuaFile("cl_damage_numbers.lua")
	AddCSLuaFile("cl_hud.lua")
	AddCSLuaFile("cl_camera.lua")
	AddCSLuaFile("cl_damage_sounds.lua")
	
	-- add fonts
	resource.AddFile("resource/fonts/TF2.ttf")
	
	-- add network strings
	util.AddNetworkString("mw_damage_number")
	util.AddNetworkString("mw_damage_sound")
end

if CLIENT then
	-- give clients certain files
	include("cl_damage_numbers.lua")
	include("cl_hud.lua")
	include("cl_camera.lua")
	include("cl_damage_sounds.lua")
end

SWEP.PrintName = "Base Weapon"
SWEP.Category = "Milkwater"
SWEP.Spawnable = false
SWEP.AdminSpawnable = true

SWEP.UseFPArms = true
SWEP.Base = "weapon_base"

SWEP.WorldModel = "models/props_junk/garbage_milkcarton002a.mdl"
SWEP.HoldType = "pistol"
SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK
SWEP.SoundShootPrimary = "Weapon_Pistol.Empty"
SWEP.Casing = "ShellEject"
SWEP.Caseless = false

SWEP.Primary.ClipSize = 12
SWEP.Primary.DefaultClip = 12
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = false
SWEP.Primary.FireDelay = 0.1
SWEP.Primary.Damage = 10
SWEP.Primary.NumShots = 1
SWEP.Primary.Recoil = 3
SWEP.Cone = 0.02

SWEP.HandOffset_Pos = Vector(0, 0, 0) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(0, 0, 0) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "MuzzleEffect"

local handWepModel = nil

local function MW_Using3PBase(ply)
    local wep = ply:GetActiveWeapon()
    return IsValid(wep) and wep.Base == "milkwaters_3p_base"
end

-- get exact camera position
function MW_GetFPCamera(ply)
	if not IsValid(ply) then return ply:EyePos() end
	
	local head = ply:LookupBone("ValveBiped.Bip01_Head1")
	
	if head then
		local matrix = ply:GetBoneMatrix(head)
		if not matrix then return ply:EyePos(), ply:EyeAngles() end
		local pos = matrix:GetTranslation()
		local ang = matrix:GetAngles()
		
		if pos and ang then
			return pos, ang
		end
	end

	return ply:EyePos(), ply:EyeAngles()
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType or "pistol")
end

function SWEP:Deploy()
    if CLIENT then
        self:CallOnClient("ForceRebuildModel")
    end
    return true
end

function SWEP:ForceRebuildModel()
    handWepModel = nil
end

-- are we allowed to attack
function SWEP:CanPrimaryAttack()
	-- check if owner exists
    local owner = self:GetOwner()
    if not IsValid(owner) then return false end
	
	-- stop client predicting in multiplayer
	if CLIENT and not IsFirstTimePredicted() then return false end
	
    -- no ammo
    if self:Clip1() <= 0 then return false end

    return true
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    -- singleplayer: ensure client also runs PrimaryAttack
    if game.SinglePlayer() then
        self:CallOnClient("PrimaryAttack")
    end

    -- fire
    self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self.Cone)

    -- ammo, sound, timing, animation
    self:TakePrimaryAmmo(1)
    self:EmitSound(self.SoundShootPrimary)
    self:SetNextPrimaryFire(CurTime() + (self.Primary.FireDelay or 0.1))
    local owner = self:GetOwner()
    if IsValid(owner) then
        owner:SetAnimation(PLAYER_ATTACK1)
    end

    -- recoil
    if SERVER then
        self:CallOnClient("DoRecoil")
    elseif CLIENT and IsFirstTimePredicted() then
        self:DoRecoil()
    end

    -- muzzle + casing effects
    local startPos, ang = self:GetMuzzlePos()
    if not startPos or not ang then return end
	
    if SERVER then
        local ed = EffectData()
        ed:SetOrigin(startPos)
        ed:SetAngles(ang)
        util.Effect(self.MuzzleEffect or "MuzzleEffect", ed, true, true)

        self:EjectCasing()
    end
end

function SWEP:SecondaryAttack()
	-- nothing?
end

function SWEP:ModifyDamage(att, tr, dmginfo)
    return dmginfo:GetDamage(), false
end

function SWEP:ShootBullet(dmg, num, cone)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
	
    -- use camera if available
	local src = MW_GetFPCamera(owner)
	local ang = owner:EyeAngles()
	local dir = ang:Forward()

    local bullet = {}
	local isMiniCrit = false
    bullet.Num = num or 1
    bullet.Src = src
    bullet.Dir = dir
    bullet.Spread = Vector(cone, cone, 0)
    bullet.Tracer = 0
    bullet.Force = force or dmg
    bullet.Damage = dmg
    bullet.AmmoType = ammo or self.Primary.Ammo
	
    bullet.Callback = function(att, tr, dmginfo)
		if CLIENT and not IsFirstTimePredicted() then return end

		local hit = tr.Entity

		-- tracer effect
		local startPos, ang = self:GetMuzzlePos()
		if not startPos or not ang then
			startPos = tr.StartPos or att:GetShootPos()
		end

		local effect = EffectData()
		effect:SetStart(startPos)
		effect:SetOrigin(tr.HitPos)
		effect:SetNormal(tr.HitNormal)
		util.Effect("milkwater_tracer", effect)

		-- apply damage modifiers
		local newDamage
		if SERVER and IsValid(att) and att:IsPlayer() then
			if IsValid(hit) then
				newDamage, isMiniCrit  = self:ModifyDamage(att, tr, dmginfo)
				if isMiniCrit then
					newDamage = newDamage * 1.35
				end
				dmginfo:SetDamage(newDamage)
			end
		end

		-- send damage number
		if SERVER and IsValid(att) and att:IsPlayer() then
			if IsValid(hit) and hit:IsNPC() then
				net.Start("mw_damage_number")
				net.WriteFloat(dmginfo:GetDamage())
				net.WriteVector(tr.HitPos)
				net.WriteUInt(hit:EntIndex(), 16)
				net.WriteBool(isMiniCrit)
				net.Send(att)
			end
		end
	end

    owner:FireBullets(bullet)
	
	-- send damage sound
	if SERVER and IsValid(owner) and owner:IsPlayer() then
		net.Start("mw_damage_sound")
		net.WriteBool(isMiniCrit)
		net.Send(owner)
	end
end

function SWEP:DoRecoil()
    local base = self.Primary.Recoil or 1

    local pitch = -base
    local yaw = math.Rand(-base * 0.25, base * 0.25)

    if MW_AddRecoil then
        MW_AddRecoil(pitch, yaw)
    end
end

function SWEP:EjectCasing()
	-- caseless guns exist
	if self.Caseless then return end
	
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
	
    local handPos, handAng = self:GetHandPos()
    if not handPos or not handAng then return end
	
    local ejectPos, ejectAng = LocalToWorld(
        Vector(10, 0, -5),
        Angle(0, 90, 0),
        handPos,
        handAng
    )

    local ed = EffectData()
    ed:SetOrigin(ejectPos)
    ed:SetAngles(ejectAng)
    ed:SetEntity(self)
    util.Effect(self.Casing, ed, true, true)
end

function SWEP:GetHandPos()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
	
    local pos = owner:EyePos()
    local ang = owner:EyeAngles()
	
    local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
    if not bone then
        return pos, ang
    end
	
    local matrix = owner:GetBoneMatrix(bone)
	local bpos = matrix:GetTranslation()
	local bang = matrix:GetAngles()
    if bpos and bang then
        pos, ang = bpos, bang
    end

    return pos, ang
end

function SWEP:GetMuzzlePos()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local handPos, handAng = self:GetHandPos()
    if not handPos or not handAng then return end
	
    local gunPos, gunAng = LocalToWorld(
        self.HandOffset_Pos or vector_origin,
        self.HandOffset_Ang or angle_zero,
        handPos,
        handAng
    )
	
    local pos, ang = LocalToWorld(
        self.MuzzleOffset_Pos or vector_origin,
        self.MuzzleOffset_Ang or angle_zero,
        gunPos,
        gunAng
    )

    return pos, ang
end

if CLIENT then
    -- handle the weapon model
	hook.Add("Think", "mw_3p_handmodel_manage", function()
		local ply = LocalPlayer()
		local wep = ply:GetActiveWeapon()

		-- not using base
		if not (IsValid(wep) and wep.Base == "milkwaters_3p_base") then
			if IsValid(handWepModel) then
				handWepModel:Remove()
				handWepModel = nil
			end
			return
		end

		-- no model yet
		if not IsValid(handWepModel) then
			handWepModel = ClientsideModel(wep.WorldModel, RENDERGROUP_OPAQUE)
			handWepModel:SetNoDraw(true)
			return
		end

		-- worldmodel changed
		if handWepModel:GetModel() ~= wep.WorldModel then
			handWepModel:Remove()
			handWepModel = ClientsideModel(wep.WorldModel, RENDERGROUP_OPAQUE)
			handWepModel:SetNoDraw(true)
		end
	end)

    -- draw gun in your hand
    hook.Add("PostDrawOpaqueRenderables", "mw_3p_draw_hand_weapon", function()
		local ply = LocalPlayer()
		local wep = ply:GetActiveWeapon()

		if not (IsValid(wep) and wep.Base == "milkwaters_3p_base") then return end
		if not IsValid(handWepModel) then return end
		
		local handPos = ply:EyePos()
		local handAng = ply:EyeAngles()

		local bone = ply:LookupBone("ValveBiped.Bip01_R_Hand")
		if bone then
			ply:SetupBones()
			local bpos, bang = ply:GetBonePosition(bone)
			if bpos and bang then
				handPos = bpos
				handAng = bang
			end
		end
		
		local finalPos, finalAng = LocalToWorld(
			wep.HandOffset_Pos or vector_origin,
			wep.HandOffset_Ang or angle_zero,
			handPos,
			handAng
		)
		
		handWepModel:SetPos(finalPos)
		handWepModel:SetAngles(finalAng)
		handWepModel:DrawModel()
	end)
	
	function SWEP:DrawWorldModel()
		self:SetNoDraw(true)
	end
end

