if SERVER then
	AddCSLuaFile()
	game.AddParticles( "particles/explosion.pcf" )
	PrecacheParticleSystem("ExplosionCore_MidAir")
end

DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.PrintName = "MW Rocket"
ENT.Spawnable = false

local impactEffect = "ExplosionCore_MidAir"
local trailEffect = "rockettrail"
local explosionSound = "weapons/explode1.wav"

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/weapons/w_models/w_rocket.mdl")

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
		
		ParticleEffectAttach(trailEffect, PATTACH_ABSORIGIN_FOLLOW, self, 0)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(2)
        end

        self.Radius = 100
    end
end

function ENT:PhysicsCollide(data, phys)
	if self.Exploded then return end
	self:Detonate(data.HitPos, data.HitNormal)
end

function ENT:StartTouch(ent)
	if self.Exploded then return end
	if ent:IsPlayer() or ent:IsNPC() then
		self:Detonate(self:GetPos(), Vector(0,0,1))
	end
end

function ENT:Detonate(pos, normal)
	if self.Exploded then return end
	self.Exploded = true
	
	-- client effect
	ParticleEffect(impactEffect, pos, normal:Angle(), nil)
	
	-- server decal
	self:MakeScorchDecal(pos, normal)
	
	-- sound
    self:EmitSound(explosionSound)
	
	-- damage
	self:DoExplosionDamage(pos)
	
	self:Remove()
end

function ENT:MakeScorchDecal(pos, normal)
    local startPos = pos + normal * 2
    local endPos   = pos - normal * 2

    util.Decal("Scorch", startPos, endPos, self)
end

function ENT:DoExplosionDamage(pos)
    local attacker = self:GetOwner()
    if not IsValid(attacker) then attacker = self end

    local entities = ents.FindInSphere(pos, self.Radius)
	
	-- get the weapon that fired the rocket
	local wep = attacker.GetActiveWeapon and attacker:GetActiveWeapon()
	local dmgAmount = wep.Primary.Damage

    for _, ent in ipairs(entities) do
        if ent:IsPlayer() or ent:IsNPC() then
            local dist = ent:GetPos():Distance(pos)
            local frac = math.Clamp(1 - (dist / self.Radius), 0, 1)

            -- half damage at edge
            local damage = Lerp(frac, dmgAmount * 0.5, dmgAmount)
			
			-- half damage for attacker
			if ent == attacker then
				damage = damage * 0.5
			end
			
			-- modify the damage more
			if IsValid(wep) and wep.ModifyDamage then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(damage)
				
				local fakeTr = {
					Entity = ent,
					HitPos = ent:GetPos(),
					HitNormal = Vector(0,0,1)
				}

				damage, isMiniCrit, isFullCrit = wep:ModifyDamage(attacker, fakeTr, dmginfo)
				
				-- increase damage based on crits
				if isFullCrit then
					damage = damage * 3
				elseif isMiniCrit then
					damage = damage * 1.35
				end
			end

            -- apply damage
            local dmg = DamageInfo()
            dmg:SetDamage(damage)
            dmg:SetDamageType(DMG_BLAST)
            dmg:SetAttacker(attacker)
            dmg:SetInflictor(self)
            dmg:SetDamagePosition(pos)

            local oldHP = ent:Health()
            ent:TakeDamageInfo(dmg)
		
			-- add time of hit for the damage numbers hook (trust me)
			ent._MW_LastHit = {attacker = attacker, crit = isFullCrit and 2 or (isMiniCrit and 1 or 0), timeHit = CurTime()}
			
			-- send damage sound
			if SERVER and IsValid(attacker) and attacker:IsPlayer() then
				net.Start("mw_damage_sound")
				net.WriteUInt(isFullCrit and 2 or (isMiniCrit and 1 or 0), 2)
				net.Send(attacker)
			end
			
			-- knockback
			local dir = (ent:GetPos() - pos):GetNormalized()
			
			local force = frac * 600

			-- self blast jump multiplier
			if ent == attacker then
				force = force * 1.4
			end

			-- apply to players
			ent:SetVelocity(ent:GetVelocity() + dir * force)

            -- gibbing logic
            if ent:IsPlayer() and (damage > oldHP + 10) then
                ent:EmitSound("physics/flesh/flesh_bloody_break.wav")
                -- you can spawn gibs here if you want
            end
        end
    end
end
