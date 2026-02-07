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
game.AddParticles("particles/muzzle_flash.pcf")
PrecacheParticleSystem("muzzle_shotgun")
PrecacheParticleSystem("muzzle_smg")

SWEP.PrintName = "Base Weapon"
SWEP.Category = "Milkwater"
SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.DrawCrosshair = false
SWEP.DrawAmmo = false

SWEP.CSMuzzleFlashes = true

SWEP.UseHands = true
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
	
	if CLIENT then
		self:CreateWorldModel()
	end
end

function SWEP:Deploy()
	if SERVER then
		net.Start("mw_name_popup")
		net.WriteFloat(CurTime() + 2)
		net.Send(self:GetOwner())
	end
	
    local owner = self:GetOwner()
    local dur = 0

    if IsValid(owner) then
        local vm = owner:GetViewModel()
        if IsValid(vm) then
            local seq = vm:SelectWeightedSequence(ACT_VM_DRAW)
            if seq and seq >= 0 then
                vm:SendViewModelMatchingSequence(seq)
                local rate = vm:GetPlaybackRate()
                if not rate or rate <= 0 then rate = 1 end
                dur = vm:SequenceDuration(seq) / rate
            end
        end
    end

    self:SetNextPrimaryFire(CurTime() + dur)
	
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

--================ PREDICTION HELPERS ================--

local function ShouldBlockPrediction()
    -- singleplayer: never block
    if game.SinglePlayer() then return false end

    -- multiplayer: block mispredicted frames
    return CLIENT and not IsFirstTimePredicted()
end

--================ PRIMARY ATTACK PIPELINE ================--

-- are we allowed to attack
function SWEP:CanPrimaryAttack()
	-- check if owner exists
    local owner = self:GetOwner()
    if not IsValid(owner) then return false end
	
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
	local isSP = game.SinglePlayer()
	
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
    if IsValid(owner) and self.PlayAttackAnim == true then
        owner:SetAnimation(PLAYER_ATTACK1)
	
		self:SendWeaponAnim(self.PrimaryAnim)
    end
	
	-- reset zoom charge
	self:SetZoomChargeProgress(0)

    -- recoil
	self:DoRecoil()
	
	if CLIENT or game.SinglePlayer() then
		self:DoMuzzleEffect()
	end
	
	if not self.LoopShootingSound then
		self:EmitSound(self.SoundShootPrimary)
	end
	
	-- extra effect on shoot (not hit)
	self:ExtraEffectOnShoot()
end

function SWEP:ShootBullet(dmg, num, cone)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
	
	local src = owner:EyePos()
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
		
		local owner = self:GetOwner()
		if not IsValid(owner) then return end

		local vm = owner:GetViewModel()
		local startPos = owner:GetShootPos()
		local attID = vm:LookupAttachment("muzzle")

		local effect = EffectData()
		effect:SetStart(startPos)
		effect:SetOrigin(tr.HitPos)
		effect:SetNormal(tr.HitNormal)
		effect:SetEntity(self)
		effect:SetAttachment(attID)
		util.Effect("milkwater_tracer", effect)


		local hit = tr.Entity
		
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

    local pos = self:GetShootPos()
	local ang = owner:EyeAngles()

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
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- base recoil value
    local r = self.Primary.Recoil or 1

    -- random horizontal sway
    local yaw = math.Rand(-0.25, 0.25) * r
    local pitch = r

    -- camera punch
    owner:ViewPunch(Angle(-pitch * 0.6, yaw * 0.4, 0))

    -- actual aim drift
    local ang = owner:EyeAngles()
    ang.p = ang.p - pitch * 0.12
    ang.y = ang.y + yaw * 0.12
    owner:SetEyeAngles(ang)
	
	if game.SinglePlayer() then
		self:CallOnClient("DoRecoil")
	end
end

--================ MUZZLE / CASING EFFECTS ================--

function SWEP:DoMuzzleEffect()
	if self.MuzzleEffect == "" then return end

	-- one-shot
	if not self.MuzzleEffectStaysWhileFiring then
		self:DoMuzzleEffect_OneShot()
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

function SWEP:DoMuzzleEffect_OneShot()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local vm = owner:GetViewModel()
	if not IsValid(vm) then return end

	local att = vm:LookupAttachment("muzzle")
	if att <= 0 then return end

	ParticleEffectAttach(
		self.MuzzleEffect,
		PATTACH_POINT,
		vm,
		att
	)
	
	if SERVER and game.SinglePlayer() then
		self:CallOnClient("DoMuzzleEffect_OneShot")
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