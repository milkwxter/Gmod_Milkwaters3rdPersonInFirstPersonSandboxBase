-- shared.lua
if SERVER then
	-- add my files
	AddCSLuaFile()
	AddCSLuaFile("cl_damage_numbers.lua")
	AddCSLuaFile("cl_hud.lua")
	AddCSLuaFile("cl_camera.lua")
	AddCSLuaFile("cl_damage_sounds.lua")
	AddCSLuaFile("sh_render.lua")
	
	-- add fonts
	resource.AddFile("resource/fonts/TF2.ttf")
	
	-- add network strings
	util.AddNetworkString("mw_damage_number")
	util.AddNetworkString("mw_damage_sound")
	util.AddNetworkString("mw_name_popup")
end

if CLIENT then
	-- give clients certain files
	include("cl_damage_numbers.lua")
	include("cl_hud.lua")
	include("cl_camera.lua")
	include("cl_damage_sounds.lua")
	include("sh_render.lua")
end

SWEP.PrintName = "Base Weapon"
SWEP.Category = "Milkwater"
SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.DrawCrosshair = false
SWEP.DrawAmmo = false

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

SWEP.Projectile = false
SWEP.ProjectileClass = ""
SWEP.ProjectileSpeed = 1000
SWEP.ProjectileGravity = false

SWEP.HandOffset_Pos = Vector(0, 0, 0) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(0, 0, 0) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "MuzzleEffect"

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
    if CLIENT or game.SinglePlayer() then
        self:CallOnClient("ForceRebuildModel")
    end
	
	if SERVER then
		net.Start("mw_name_popup")
		net.WriteFloat(CurTime() + 2)
		net.Send(self:GetOwner())
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
    if self:Clip1() <= 0 then 
		self:Reload()
		return false 
	end

    return true
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    -- singleplayer: ensure client also runs PrimaryAttack
    if game.SinglePlayer() then
        self:CallOnClient("PrimaryAttack")
    end

    -- fire
	if self.Projectile then
		self:ShootProjectile()
	else
		self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self.Cone)
	end

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
    local hit = tr.Entity
    local dmg = dmginfo:GetDamage()
	
    local isMiniCrit = false
	local isFullCrit = false

    -- minicrits if the target is jarated
    if IsValid(hit) and hit._JarateTimer then
        isMiniCrit = true
    end
	
    return dmg, isMiniCrit, isFullCrit
end

function SWEP:ExtraEffectOnHit(att, tr)
	-- call me in the child weapon
end

function SWEP:ShootBullet(dmg, num, cone)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
	
    -- use camera if available
	local src = MW_GetFPCamera(owner)
	local ang = owner:EyeAngles()
	local dir = ang:Forward()

    local bullet = {}
	
	-- crit state
	local isMiniCrit = false
	local isFullCrit = false
	
    bullet.Num = num or 1
    bullet.Src = src
    bullet.Dir = dir
    bullet.Spread = Vector(cone, cone, 0)
    bullet.Tracer = 0
    bullet.Force = force or dmg
    bullet.Damage = dmg
	bullet.HullSize = 0.1
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
				newDamage, isMiniCrit, isFullCrit = self:ModifyDamage(att, tr, dmginfo)
				
				-- increase damage based on crits
				if isFullCrit then
					newDamage = newDamage * 3
				elseif isMiniCrit then
					newDamage = newDamage * 1.35
				end
				
				-- finish the calcs
				dmginfo:SetDamage(newDamage)
				
				-- add time of hit for the damage numbers hook (trust me)
				hit._MW_LastHit = {attacker = att, crit = isFullCrit and 2 or (isMiniCrit and 1 or 0), timeHit = CurTime()}
				
				-- perform a magic extra effect
				self:ExtraEffectOnHit(att, tr)
			end
		end
	end

    owner:FireBullets(bullet)
	
	-- send damage sound
	if SERVER and IsValid(owner) and owner:IsPlayer() then
		net.Start("mw_damage_sound")
		net.WriteUInt(isFullCrit and 2 or (isMiniCrit and 1 or 0), 2)
		net.Send(owner)
	end
end

hook.Add("ScalePlayerDamage", "mw_disable_hitgroups_player", function(ply, hitgroup, dmginfo)
	local attacker = dmginfo:GetAttacker()
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	
	local wep = attacker:GetActiveWeapon()
	if not IsValid(wep) then return end
	
    -- remove all hitgroup scaling for my guns
	if wep.Base == "milkwaters_3p_base" then
		return false
	end
end)

hook.Add("ScaleNPCDamage", "mw_disable_hitgroups_npc", function(ply, hitgroup, dmginfo)
	local attacker = dmginfo:GetAttacker()
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	
	local wep = attacker:GetActiveWeapon()
	if not IsValid(wep) then return end
	
    -- remove all hitgroup scaling for my guns
	if wep.Base == "milkwaters_3p_base" then
		return false
	end
end)

-- damage numbers hook
hook.Add("EntityTakeDamage", "mw_damage_numbers", function(ent, dmginfo)
    local tag = ent._MW_LastHit
    if not tag then return end
    if tag.timeHit < CurTime() - 0.1 then return end

    local att = tag.attacker
    if not (IsValid(att) and att:IsPlayer()) then return end

    net.Start("mw_damage_number")
    net.WriteFloat(dmginfo:GetDamage())
    net.WriteVector(ent:WorldSpaceCenter())
    net.WriteUInt(ent:EntIndex(), 16)
    net.WriteUInt(tag.crit, 2)
    net.Send(att)

    ent._MW_LastHit = nil
end)

function SWEP:ShootProjectile()
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local pos, ang = self:GetMuzzlePos()
    if not pos or not ang then return end
	
	ang = owner:EyeAngles()

    local ent = ents.Create(self.ProjectileClass)
    if not IsValid(ent) then return end

    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:SetOwner(owner)
	
	ent.Damage = self.Primary.Damage
	
    ent:Spawn()
    ent:Activate()

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(ang:Forward() * self.ProjectileSpeed)
        if not self.ProjectileGravity then
            phys:EnableGravity(false)
        end
    end

    return ent
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