if SERVER then
	AddCSLuaFile()
end

-- cache my particles
game.AddParticles( "particles/rockettrail.pcf" )
PrecacheParticleSystem("flaregun_trail_red")

DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.PrintName = "MW Flare"
ENT.Spawnable = false

ENT.TrailEffect = "flaregun_trail_red"

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/weapons/w_models/w_flaregun_shell.mdl")

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(1)
        end
		
		-- get the weapon that fired the flare
		local attacker = self:GetOwner()
		self.Weapon = attacker.GetActiveWeapon and attacker:GetActiveWeapon()
		self.DmgAmount = self.Weapon.Primary.Damage
    end
	
	if CLIENT or game.SinglePlayer() then
		ParticleEffectAttach(self.TrailEffect, PATTACH_ABSORIGIN_FOLLOW, self, 0)
	end
end

function ENT:PhysicsCollide(data, phys)
    if self.Hit then return end
    self.Hit = true

    local hitEnt = data.HitEntity
    local hitPos = data.HitPos
    local hitNormal = data.HitNormal

    self:DoIgnite(hitEnt, hitPos, hitNormal)
    self:Remove()
end

function ENT:StartTouch(ent)
    if self.Hit then return end
    self.Hit = true

    self:DoIgnite(ent, self:GetPos(), Vector(0,0,1))
    self:Remove()
end

function ENT:DoIgnite(ent, pos, normal)
	if not IsValid(ent) then return end
    if not (ent:IsPlayer() or ent:IsNPC()) then return end

    local attacker = self:GetOwner()
    if not IsValid(attacker) then attacker = self end
	
	local isBurning = ent:IsOnFire()

    -- ignite for 6 seconds
    ent:Ignite(6)
	
	-- deal damage
	local wep = self.Weapon
	local dmgAmount = self.DmgAmount
	local isMiniCrit = false
	local isFullCrit = false
	
	-- modify the damage
	if IsValid(wep) and wep.ModifyDamage then
		local dmginfo = DamageInfo()
		dmginfo:SetDamage(dmgAmount)
		
		local fakeTr = {
			Entity = ent,
			HitPos = ent:GetPos(),
			HitNormal = Vector(0,0,1)
		}

		dmgAmount, isMiniCrit, isFullCrit = wep:ModifyDamage(attacker, fakeTr, dmginfo)
		
		if isBurning then
			isFullCrit = true
		end
		
		-- increase damage based on crits
		if isFullCrit then
			dmgAmount = dmgAmount * 3
		elseif isMiniCrit then
			dmgAmount = dmgAmount * 1.35
		end
	end
	
	local dmg = DamageInfo()
	dmg:SetDamage(dmgAmount)
	dmg:SetDamageType(DMG_BURN)
	dmg:SetAttacker(attacker)
	dmg:SetInflictor(self)
	dmg:SetDamagePosition(pos)
	ent:TakeDamageInfo(dmg)

	-- add time of hit for the damage numbers hook (trust me)
	ent._MW_LastHit = {attacker = attacker, crit = isFullCrit and 2 or (isMiniCrit and 1 or 0), timeHit = CurTime()}
	
	-- send damage sound
	if SERVER and IsValid(attacker) and attacker:IsPlayer() then
		net.Start("mw_damage_sound")
		net.WriteUInt(isFullCrit and 2 or (isMiniCrit and 1 or 0), 2)
		net.Send(attacker)
	end
end
