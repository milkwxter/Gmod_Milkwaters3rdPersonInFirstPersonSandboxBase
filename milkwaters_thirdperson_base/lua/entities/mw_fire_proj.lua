if SERVER then 
	AddCSLuaFile() 
end

DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.PrintName = "MW Flame Puff"
ENT.Spawnable = false

if SERVER then
    AddCSLuaFile()

    ENT.LifeTime = 0.4
    ENT.Speed = 1000
    ENT.Size = 2
	
	ENT._DebugDisplay = false

    function ENT:Initialize()
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

        self.DieTime = CurTime() + self.LifeTime
        self.LastPos = self:GetPos()

        self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
		self:SetColor(Color(255, 100, 0))
		self:SetMaterial("models/debug/debugwhite")
		self:SetNoDraw(not _DebugDisplay)
    end

    function ENT:Think()
        if not self.DieTime then
            self.DieTime = CurTime() + self.LifeTime
        end

        if CurTime() > self.DieTime then
            self:Remove()
            return
        end

        local dt = FrameTime()
        local newPos = self:GetPos() + self:GetForward() * self.Speed * dt

        local tr = util.TraceHull({
            start  = self:GetPos(),
            endpos = newPos,
            mins   = Vector(-self.Size, -self.Size, -self.Size),
            maxs   = Vector( self.Size,  self.Size,  self.Size),
            filter = { self, self:GetOwner() }
        })

        if tr.Hit then
			self:OnHit(tr)

			-- bounce logic
			local normal = tr.HitNormal
			local incoming = self:GetForward()

			-- reflect direction
			local reflected = incoming - 2 * incoming:Dot(normal) * normal
			self:SetAngles(reflected:Angle())

			-- reduce speed slightly so it feels soft
			self.Speed = self.Speed * 0.6

			-- move slightly off the surface to avoid sticking
			self:SetPos(tr.HitPos + normal * 2)

			self:NextThink(CurTime())
			return true
		end

        self:SetPos(newPos)
        self:NextThink(CurTime())
        return true
    end

    function ENT:OnHit(tr)
		local ent = tr.Entity
		if not IsValid(ent) then return end

		local attacker = self:GetOwner()
		if not IsValid(attacker) then attacker = self end

		-- props
		if ent:GetMoveType() == MOVETYPE_VPHYSICS then
			-- ignite props
			ent:Ignite(6, 0)

			-- push them a bit
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:ApplyForceOffset(self:GetForward() * 200, tr.HitPos)
			end

			return
		end

		-- living people
		if ent:IsPlayer() or ent:IsNPC() then
			ent:Ignite(6, 0)

			-- per target flame tick cooldown
			ent._NextFlameDamage = ent._NextFlameDamage or 0
			if CurTime() < ent._NextFlameDamage then return end
			ent._NextFlameDamage = CurTime() + 0.075

			-- damage calculation
			local wep = attacker.GetActiveWeapon and attacker:GetActiveWeapon()
			local dmgAmount = wep and wep.Primary and wep.Primary.Damage or 5

			if IsValid(wep) and wep.ModifyDamage then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(dmgAmount)

				local fakeTr = {
					Entity = ent,
					HitPos = ent:GetPos(),
					HitNormal = Vector(0,0,1)
				}

				dmgAmount, isMiniCrit, isFullCrit = wep:ModifyDamage(attacker, fakeTr, dmginfo)

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
			dmg:SetDamagePosition(tr.HitPos)
			ent:TakeDamageInfo(dmg)

			ent._MW_LastHit = {
				attacker = attacker,
				crit = isFullCrit and 2 or (isMiniCrit and 1 or 0),
				timeHit = CurTime()
			}

			if SERVER and IsValid(attacker) and attacker:IsPlayer() then
				net.Start("mw_damage_sound")
				net.WriteUInt(isFullCrit and 2 or (isMiniCrit and 1 or 0), 2)
				net.Send(attacker)
			end

			return
		end
	end
end