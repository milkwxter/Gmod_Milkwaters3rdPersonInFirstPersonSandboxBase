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
AddCSLuaFile("cl_pyrovision.lua")
AddCSLuaFile("cl_sniper_dot.lua")
AddCSLuaFile("sh_render.lua")
AddCSLuaFile("sh_sound.lua")
AddCSLuaFile("sh_damage.lua")
AddCSLuaFile("sh_reload.lua")
AddCSLuaFile("sh_melee.lua")


-- give clients certain files
if CLIENT then
	include("cl_damage_numbers.lua")
	include("cl_hud.lua")
	include("cl_camera.lua")
	include("cl_damage_sounds.lua")
	include("cl_pyrovision.lua")
	include("cl_sniper_dot.lua")
end

-- rest of the files are for everyone
include("sh_render.lua")
include("sh_sound.lua")
include("sh_damage.lua")
include("sh_reload.lua")
include("sh_melee.lua")

-- cache common particles
if SERVER then
    game.AddParticles("particles/muzzle_flash.pcf")
    PrecacheParticleSystem("muzzle_shotgun")
    PrecacheParticleSystem("muzzle_smg")
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

SWEP.LoopShootingSound = false
SWEP.SoundShootPrimary = "Weapon_Pistol.Empty"
SWEP.SoundShootLoop = ""
SWEP.SoundShootEnd = ""

SWEP.Casing = "ShellEject"
SWEP.Caseless = false
SWEP.PlayAttackAnim = true
SWEP.TracerName = "milkwater_tracer"

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

SWEP.EnablePyroland = false

SWEP.CanZoom = false
SWEP.Zoomed = false
SWEP.ZoomFOV = 20
SWEP.ZoomCharge = true
SWEP.ZoomDot = "effects/sniperdot"

SWEP.Melee = false
SWEP.MeleeDamage = 25
SWEP.MeleeRange = 70
SWEP.MeleeDelay = 0.2
SWEP.MeleeHitSound = "weapons/cbar_hitbod1.wav"
SWEP.MeleeSwingSound = "weapons/cbar_miss1.wav"

--================ SETUP / INITIALIZATION ================--

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "Zoomed")
	self:NetworkVar("Float", 0, "ZoomChargeProgress")
	self:NetworkVar("Vector", 0, "ZoomDotPos")
	self:NetworkVar("String", 0, "CurrentWorldModel")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType or "pistol")
	
	if SERVER then 
		self:SetCurrentWorldModel(self.WorldModel or "models/props_junk/garbage_milkcarton002a.mdl")
	end
	
	if CLIENT then self:CreateWorldModel() end
end

function SWEP:Deploy()
	if SERVER then
		net.Start("mw_name_popup")
		net.WriteFloat(CurTime() + 2)
		net.Send(self:GetOwner())
	end
	
	if CLIENT then self:CreateWorldModel() end
	
    return true
end

function SWEP:Holster()
    self:MW_StopLoopingSound()
	self:SetZoomed(false)
    return true
end

function SWEP:OnRemove()
    self:MW_StopLoopingSound()
	self:SetZoomed(false)
end

local function MW_Using3PBase(ply)
    local wep = ply:GetActiveWeapon()
    return IsValid(wep) and wep.Base == "milkwaters_3p_base"
end

if CLIENT then
	function SWEP:CreateWorldModel()
		if IsValid(self.WModel) then return end

        local mdl = self.GetCurrentWorldModel and self:GetCurrentWorldModel() or self.WorldModel
        self.WModel = ClientsideModel(mdl, RENDERGROUP_OPAQUE)
        self.WModel:SetNoDraw(true)
	end
end

--================ PREDICTION HELPERS ================--

local function ShouldBlockPrediction()
    -- singleplayer: never block
    if game.SinglePlayer() then return false end

    -- multiplayer: block mispredicted frames
    return CLIENT and not IsFirstTimePredicted()
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

--================ PRIMARY ATTACK PIPELINE ================--

-- are we allowed to attack
function SWEP:CanPrimaryAttack()
	-- check if owner exists
    local owner = self:GetOwner()
    if not IsValid(owner) then return false end
	
	-- stop client predicting in multiplayer
	if ShouldBlockPrediction() then return false end
	
	-- melee time
	if self.Melee then return true end
	
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
	
    local owner = self:GetOwner()
	
	-- timing
    self:SetNextPrimaryFire(CurTime() + (self.Primary.FireDelay or 0.1))

    -- fire
	if self.Projectile then
		for i = 1, self.Primary.NumShots do
			self:ShootProjectile()
		end
	elseif self.Melee then
		self:DoMeleeAttack()
		return
	else
		self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self.Cone)
	end

    -- ammo, sound, animation
    self:TakePrimaryAmmo(1)
	if not self.LoopShootingSound then
		self:EmitSound(self.SoundShootPrimary)
	end
    if IsValid(owner) and self.PlayAttackAnim == true then
        owner:SetAnimation(PLAYER_ATTACK1)
    end
	
	-- reset zoom charge
	self:SetZoomChargeProgress(0)

    -- recoil
    if SERVER then
        self:CallOnClient("DoRecoil")
    elseif CLIENT and IsFirstTimePredicted() then
        self:DoRecoil()
    end

    -- muzzle + casing effects
    if SERVER then
        self:EjectCasing()
    end
	
	if CLIENT or game.SinglePlayer() then
		self:DoMuzzleEffect()
	end
	
	-- extra effect on shoot (not hit)
	self:ExtraEffectOnShoot()
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
	local isMiniCrit, isFullCrit = false, false
	
    bullet.Num = num or 1
    bullet.Src = src
    bullet.Dir = dir
    bullet.Spread = Vector(cone, cone, 0)
    bullet.Tracer = 0
    bullet.Force = dmg
    bullet.Damage = dmg
	bullet.HullSize = 0.1
    bullet.AmmoType = self.Primary.Ammo
	
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
		util.Effect(self.TracerName, effect)

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

function SWEP:ShootProjectile()
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local pos, ang = self:GetMuzzlePos()
	if not pos or not ang then return end

	-- use players aim
	ang = owner:EyeAngles()

	-- apply cone spread
	if self.Cone and self.Cone > 0 then
		local cone = math.rad(self.Cone)
		local rand = VectorRand():GetNormalized() * math.tan(cone)
		ang = (ang:Forward() + rand):Angle()
	end
	
	pos, blocked = self:ResolveMuzzleCollision(owner, pos)

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

--================ MUZZLE / CASING EFFECTS ================--

function SWEP:DoMuzzleEffect()
	if self.MuzzleEffect == "" then return end

	local startPos, ang = self:GetMuzzlePos()
	if not startPos or not ang then return end

	-- one-shot
	if not self.MuzzleEffectStaysWhileFiring then
		ParticleEffect(self.MuzzleEffect, startPos, ang, self)
		return
	end

	-- looping
	if not IsValid(self.MuzzleLoop) then
		if CLIENT then
			self:DoMuzzleEffect_Looping()
		end
		if game.SinglePlayer() then
			self:CallOnClient("DoMuzzleEffect_Looping")
		end
	end
end

if CLIENT then
	function SWEP:DoMuzzleEffect_Looping()
		if IsValid(self.MuzzleLoop) then return end
		
		local att = self:LookupAttachment("muzzle")
		if not att or att <= 0 then att = 1 end

		-- attach to the model
		self.MuzzleLoop = CreateParticleSystem( self.WModel, self.MuzzleEffect, PATTACH_POINT_FOLLOW, att )
	end

    function SWEP:StopMuzzleEffect()
        if IsValid(self.MuzzleLoop) then
            self.MuzzleLoop:StopEmission(false, true)
            self.MuzzleLoop = nil
        end
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

--================ CAMERA / TRANSFORM UTILITIES ================--

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

function SWEP:ResolveMuzzleCollision(owner, muzzlePos)
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

--================ GOATED THINK ================--

function SWEP:Think()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	
    if self.Reloading and CurTime() >= self.ReloadEnd then
        self:FinishReload()
    end
	
	-- increment zoom charge
	if self.ZoomCharge and self:GetZoomed() then
		local target = self:GetZoomed() and 1 or 0
		local cur = self:GetZoomChargeProgress()
		local speed = FrameTime() * (1 / 3)
		self:SetZoomChargeProgress(math.Approach(cur, target, speed))
		
		-- trace where the player is aiming
		local camPos = owner.MW_CamPos or owner:EyePos()
		local camAng = owner.MW_CamAng or owner:EyeAngles()
		
		local startPos = camPos
		local endPos = camPos + camAng:Forward() * 90000
		
		local tr = util.TraceLine({ start = startPos, endpos = endPos, filter = owner, mask = MASK_SHOT })
		
		self:SetZoomDotPos(tr.HitPos)
	else
		-- hide dot
		self:SetZoomDotPos(vector_origin)
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

--================ SECONDARY ATTACK PIPELINE ================--

function SWEP:SecondaryAttack()
    if ShouldBlockPrediction() then return end
	
	if self.CanZoom then
		local newZoom = not self:GetZoomed()

		self:SetZoomed(newZoom)
	
		-- reset zoom charge
		self:SetZoomChargeProgress(0)
	end
	
    self:SetNextSecondaryFire(CurTime() + 0.2)
end

--================ HUD DRAWING ================--

function SWEP:DrawHUDBackground()
    if self.EnablePyroland then
        self:DrawHUDPyrovision()
    end

    if self.CanZoom and self:GetZoomed() then
        self:DrawSniperScope()
    end
	
	if self:GetZoomed() and self:Clip1() > 0 and self.ZoomCharge then
		self:DrawSniperCharge()
	end
end