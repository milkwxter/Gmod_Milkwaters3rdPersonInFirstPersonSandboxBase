if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("mw_stop_jarate_drip")
end

-- cache my particles
game.AddParticles( "particles/item_fx.pcf" )
PrecacheParticleSystem("peejar_impact")
PrecacheParticleSystem("peejar_drips")

DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.PrintName = "MW Jarate"
ENT.Spawnable = false

local impactEffect = "peejar_impact"
local dripEffect = "peejar_drips"

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/weapons/c_models/urinejar.mdl")

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(2)
			phys:AddAngleVelocity(VectorRand() * 300)
        end

        self.Radius = 200
        self.Duration = 10
    end
end

function ENT:PhysicsCollide(data, phys)
    if self.Exploded then return end
    self.Exploded = true

    local pos = data.HitPos
    local normal = data.HitNormal

    -- defer everything to avoid physics warnings
    timer.Simple(0, function()
        if not IsValid(self) then return end

        -- play impact effect
        ParticleEffect(impactEffect, pos, data.HitNormal:Angle(), nil)

        -- impact sound
        self:EmitSound("weapons/jar_explode.wav", 75, 100)
		
		-- aoe effect
		for _, ent in ipairs(ents.FindInSphere(pos, self.Radius)) do
			if ent:IsPlayer() or ent:IsNPC() then
				self:ApplyJarate(ent)
			end
		end

        -- remove instantly
        self:Remove()
    end)
end

function ENT:ApplyJarate(ent)
    if not IsValid(ent) then return end

    -- store original color once
    if not ent._OriginalColor then
        ent._OriginalColor = ent:GetColor()
    end

    -- apply yellow tint
    ent:SetColor(Color(255, 255, 0, 255))

    -- tell client to stop the drip
	net.Start("mw_stop_jarate_drip")
	net.WriteUInt(ent:EntIndex(), 16)
	net.Broadcast()

    -- attach new drip effect
    ParticleEffectAttach(dripEffect, PATTACH_ABSORIGIN_FOLLOW, ent, 0)

    -- kill old timer if it exists
    if ent._JarateTimer then
        timer.Remove(ent._JarateTimer)
    end

    -- create a unique timer ID for this entity
    ent._JarateTimer = "jarate_timer_" .. ent:EntIndex()
    timer.Create(ent._JarateTimer, self.Duration, 1, function()
		if not IsValid(ent) then return end

		-- restore color
		ent:SetColor(ent._OriginalColor or Color(255,255,255))
		ent._OriginalColor = nil

		-- tell client to stop the drip
		net.Start("mw_stop_jarate_drip")
		net.WriteUInt(ent:EntIndex(), 16)
		net.Broadcast()

		ent._JarateTimer = nil
	end)
end

if CLIENT then
	net.Receive("mw_stop_jarate_drip", function()
		local entIndex = net.ReadUInt(16)
		local ent = Entity(entIndex)

		if IsValid(ent) then
			ent:StopParticlesNamed(dripEffect)
		end
	end)
end