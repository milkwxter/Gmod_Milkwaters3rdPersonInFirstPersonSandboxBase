-- shared.lua
if SERVER then
	-- add fonts
	resource.AddFile("resource/fonts/TF2.ttf")
	
	-- add network strings
	util.AddNetworkString("mw_damage_number")
	util.AddNetworkString("mw_damage_sound")
	util.AddNetworkString("mw_name_popup")
end

-- add my files
AddCSLuaFile()
AddCSLuaFile("cl_damage_numbers.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_camera.lua")
AddCSLuaFile("cl_damage_sounds.lua")
AddCSLuaFile("sh_render.lua")
AddCSLuaFile("sh_sound.lua")

-- give clients certain files
if CLIENT then
	include("cl_damage_numbers.lua")
	include("cl_hud.lua")
	include("cl_camera.lua")
	include("cl_damage_sounds.lua")
end

-- rest of the files are for everyone
include("sh_render.lua")
include("sh_sound.lua")

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

SWEP.LoopShootingSound = false
SWEP.SoundShootPrimary = "Weapon_Pistol.Empty"
SWEP.SoundShootLoop = ""
SWEP.SoundShootEnd = ""

SWEP.Casing = "ShellEject"
SWEP.Caseless = false
SWEP.PlayAttackAnim = true

SWEP.Primary.ClipSize = 12
SWEP.Primary.DefaultClip = 12
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Automatic = false
SWEP.Primary.FireDelay = 0.1
SWEP.Primary.Damage = 10
SWEP.Primary.NumShots = 1
SWEP.Primary.Recoil = 3
SWEP.Cone = 0.02

SWEP.ReloadTime = 2.0
SWEP.ReloadGesture = ACT_HL2MP_GESTURE_RELOAD_AR2

SWEP.Projectile = false
SWEP.ProjectileClass = ""
SWEP.ProjectileSpeed = 1000
SWEP.ProjectileGravity = false

SWEP.HandOffset_Pos = Vector(0, 0, 0) -- forward, right, up
SWEP.HandOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll

SWEP.MuzzleOffset_Pos = Vector(0, 0, 0) -- forward, right, up
SWEP.MuzzleOffset_Ang = Angle(0, 0, 0) -- pitch, yaw, roll
SWEP.MuzzleEffect = "muzzle_shotgun"
SWEP.MuzzleEffectStaysWhileFiring = false

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
	if SERVER then
		net.Start("mw_name_popup")
		net.WriteFloat(CurTime() + 2)
		net.Send(self:GetOwner())
	end
	
    return true
end

function SWEP:Holster()
    self:MW_StopLoopingSound()
    return true
end

function SWEP:OnRemove()
    self:MW_StopLoopingSound()
end

local function ShouldBlockPrediction()
    -- singleplayer: never block
    if game.SinglePlayer() then return false end

    -- multiplayer: block mispredicted frames
    return CLIENT and not IsFirstTimePredicted()
end

-- are we allowed to attack
function SWEP:CanPrimaryAttack()
	-- check if owner exists
    local owner = self:GetOwner()
    if not IsValid(owner) then return false end
	
	-- stop client predicting in multiplayer
	if ShouldBlockPrediction() then return false end
	
    -- no ammo
    if self:Clip1() <= 0 then
		if CLIENT then
			self:StopMuzzleEffect()
		end
		
		return false 
	end
	
	-- you cant shoot and reload
    if self.Reloading then return false end

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
	if not self.LoopShootingSound then
		self:EmitSound(self.SoundShootPrimary)
	end
    
    self:SetNextPrimaryFire(CurTime() + (self.Primary.FireDelay or 0.1))
    local owner = self:GetOwner()
    if IsValid(owner) and self.PlayAttackAnim == true then
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
        self:EjectCasing()
    end
	
	if CLIENT or game.SinglePlayer() then
		self:DoMuzzleEffect()
	end
end

function SWEP:DoMuzzleEffect()
	if self.MuzzleEffect == "" then return end

	local startPos, ang = self:GetMuzzlePos()
	if not startPos or not ang then return end

	local att = self:LookupAttachment("muzzle") or 1

	-- one-shot
	if not self.MuzzleEffectStaysWhileFiring then
		ParticleEffect(self.MuzzleEffect, startPos, ang, self)
		return
	end

	-- looping
	if not IsValid(self.MuzzleLoop) then
		self:CallOnClient("DoMuzzleEffect_Looping", att)
	end
end

if CLIENT then
    function SWEP:DoMuzzleEffect_Looping(att)
        if not IsValid(self.MuzzleLoop) then
            self.MuzzleLoop = CreateParticleSystem(self, self.MuzzleEffect, PATTACH_POINT, att)
        end
    end

    function SWEP:StopMuzzleEffect()
        if IsValid(self.MuzzleLoop) then
            self.MuzzleLoop:StopEmission(false, true)
            self.MuzzleLoop = nil
        end
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

function SWEP:CanReload()
    if self.Reloading then return false end

    -- clip already full
    if self:Clip1() >= self.Primary.ClipSize then return false end

    local owner = self:GetOwner()
    if not IsValid(owner) then return false end

    -- no reserve ammo
    if owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return false end

    return true
end

function SWEP:Reload()
    if not self:CanReload() then return end
    self:StartReload()
end

function SWEP:StartReload()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self.Reloading = true
    self.ReloadEnd = CurTime() + self.ReloadTime

    -- play 3p animation
    owner:DoAnimationEvent(self.ReloadGesture)
	
	-- stop looping sound
	self:MW_StopLoopingSound()
end

function SWEP:FinishReload()
    self.Reloading = false

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local ammo = owner:GetAmmoCount(self.Primary.Ammo)
    local needed = self.Primary.ClipSize - self:Clip1()

    local toLoad = math.min(needed, ammo)

    self:SetClip1(self:Clip1() + toLoad)
    owner:SetAmmo(ammo - toLoad, self.Primary.Ammo)
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

local function ResolveMuzzleCollision(owner, muzzlePos)
    local eye = owner:EyePos()
	
    local tr1 = util.TraceLine({
        start  = eye,
        endpos = muzzlePos,
        filter = owner,
        mask   = MASK_SOLID_BRUSHONLY
    })
	
    local tr2 = util.TraceLine({
        start  = muzzlePos,
        endpos = eye,
        filter = owner,
        mask   = MASK_SOLID_BRUSHONLY
    })
	
    if tr1.Hit or tr2.Hit then
        return eye, true
    end

    return muzzlePos, false
end

function SWEP:ShootProjectile()
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local pos, ang = self:GetMuzzlePos()
	if not pos or not ang then return end

	-- use player's aim
	ang = owner:EyeAngles()

	-- apply cone spread
	if self.Cone and self.Cone > 0 then
		local cone = math.rad(self.Cone)
		local rand = VectorRand():GetNormalized() * math.tan(cone)
		ang = (ang:Forward() + rand):Angle()
	end
	
	pos, blocked = ResolveMuzzleCollision(owner, pos)

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

function SWEP:Think()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
    if self.Reloading and CurTime() >= self.ReloadEnd then
        self:FinishReload()
    end
	
	if self.LoopShootingSound then
		if owner:KeyPressed(IN_ATTACK) and self:CanPrimaryAttack() then
			self:PlayShootSound()
		elseif not self:CanPrimaryAttack() then
			self:MW_StopLoopingSound()
		end
		
		self:Think_SoundSystem()
	end
	
	if CLIENT then
		if not self:GetOwner():KeyDown(IN_ATTACK) then
			self:StopMuzzleEffect()
		end
	end
end
