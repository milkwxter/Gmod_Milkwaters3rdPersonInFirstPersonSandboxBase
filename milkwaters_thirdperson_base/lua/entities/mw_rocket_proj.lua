if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("mw_rocket_light")
end

-- cache my particles
game.AddParticles( "particles/explosion.pcf" )
game.AddParticles( "particles/rockettrail.pcf" )
PrecacheParticleSystem("ExplosionCore_MidAir")
PrecacheParticleSystem("rockettrail")

DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.PrintName = "MW Rocket"
ENT.Spawnable = false

ENT.TrailEffect = "rockettrail"

local impactEffect = "ExplosionCore_MidAir"
local explosionSound = "weapons/explode1.wav"

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/weapons/w_models/w_rocket.mdl")

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(2)
        end

        self.Radius = 169
		
		-- get the weapon that fired the rocket
		local attacker = self:GetOwner()
		self.Weapon = attacker.GetActiveWeapon and attacker:GetActiveWeapon()
		self.DmgAmount = self.Weapon.Primary.Damage
    end
	
	if CLIENT or game.SinglePlayer() then
		ParticleEffectAttach(self.TrailEffect, PATTACH_ABSORIGIN_FOLLOW, self, 0)
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
	
	-- dynamic light for clients
	net.Start("mw_rocket_light")
	net.WriteVector(pos)
	net.Broadcast()
	
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

    for _, ent in ipairs(entities) do
        if ent:IsPlayer() or ent:IsNPC() then
			-- los check
			local tr = util.TraceLine({
				start = pos,
				endpos = ent:WorldSpaceCenter(),
				filter = { self, attacker },
				mask = MASK_SOLID_BRUSHONLY
			})

			-- if we hit something else, continue
			if tr.Hit and tr.Entity ~= ent then
				continue
			end

            local dist = ent:GetPos():Distance(pos)
            local frac = math.Clamp(1 - (dist / self.Radius), 0, 1)

            -- half damage at edge
            local damage = Lerp(frac, self.DmgAmount * 0.5, self.DmgAmount)
			
			-- half damage for attacker
			if ent == attacker then
				damage = damage * 0.5
			end
			
			-- modify the damage more
			if IsValid(self.Weapon) and self.Weapon.ModifyDamage then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(damage)
				
				local fakeTr = {
					Entity = ent,
					HitPos = ent:GetPos(),
					HitNormal = Vector(0,0,1)
				}

				damage, isMiniCrit, isFullCrit = self.Weapon:ModifyDamage(attacker, fakeTr, dmginfo)
				
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
        end
		
		-- other stuff gets knocked around
		if ent:GetMoveType() == MOVETYPE_VPHYSICS then
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				local dist = ent:GetPos():Distance(pos)
				local frac = math.Clamp(1 - (dist / self.Radius), 0, 1)
				
				local dir = (ent:GetPos() - pos):GetNormalized()
				
				local force = frac * 100000

				-- scale by mass so heavy props move less
				force = force / math.max(phys:GetMass() * 0.1, 1)

				phys:ApplyForceCenter(dir * force)
			end
		end
    end
end

if CLIENT then
    net.Receive("mw_rocket_light", function()
        local pos = net.ReadVector()

        local dlight = DynamicLight(0)
        if dlight then
            dlight.pos = pos
            dlight.r = 255
            dlight.g = 150
            dlight.b = 50
            dlight.brightness = 4
            dlight.Decay = 800
            dlight.Size = 200
            dlight.DieTime = CurTime() + 1
        end
    end)
end
