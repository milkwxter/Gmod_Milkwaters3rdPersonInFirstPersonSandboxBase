if SERVER then 
	AddCSLuaFile() 
end

DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.PrintName = "MW Flame Puff"
ENT.Spawnable = false

if SERVER then
    AddCSLuaFile()

    ENT.LifeTime = 0.30
    ENT.Speed = 1500
    ENT.Size = 2
	
	ENT._DebugDisplay = false

    function ENT:Initialize()
        self:SetModel("models/hunter/misc/sphere025x025.mdl")

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

        self.DieTime = CurTime() + self.LifeTime
		self:SetColor(Color(255, 100, 0))
		self:SetMaterial("models/debug/debugwhite")
		self:SetNoDraw(not self._DebugDisplay)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(1)
        end
		
		-- get the weapon that fired the flame puff
		local attacker = self:GetOwner()
		self.Weapon = attacker.GetActiveWeapon and attacker:GetActiveWeapon()
		self.DmgAmount = self.Weapon.Primary.Damage
    end
	
	function ENT:PhysicsCollide(data, phys)
		local hit = data.HitEntity
		if hit == self then return end
		if hit:GetClass() == "mw_fire_proj" then return end

		self:OnHit(hit, data.HitPos, data.HitNormal)
	end

    function ENT:Think()
        if CurTime() > self.DieTime then
            self:Remove()
            return
        end
		
        self:NextThink(CurTime())
        return true
    end

    function ENT:OnHit(ent, hitpos, hitnormal)
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
				phys:ApplyForceOffset(self:GetForward() * 200, ent:GetPos())
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
			local dmgAmount = self.DmgAmount
			local isMiniCrit, isFullCrit = false, false

			if IsValid(self.Weapon) and self.Weapon.ModifyDamage then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(dmgAmount)

				local fakeTr = {
					Entity = ent,
					HitPos = ent:GetPos(),
					HitNormal = Vector(0,0,1)
				}

				dmgAmount, isMiniCrit, isFullCrit = self.Weapon:ModifyDamage(attacker, fakeTr, dmginfo)

				if isFullCrit then
					dmgAmount = dmgAmount * 3
				elseif isMiniCrit then
					dmgAmount = dmgAmount * 1.35
				end
			end

			local dmg = DamageInfo()
			dmg:SetDamage(dmgAmount)
			dmg:SetDamageType(DMG_GENERIC)
			dmg:SetAttacker(attacker)
			dmg:SetInflictor(self)
			dmg:SetDamagePosition(ent:GetPos())
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