if SERVER then AddCSLuaFile() end

DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.PrintName = "MW Syringe"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "StickEntity")
    self:NetworkVar("Int", 0, "StickBone")
    self:NetworkVar("Vector", 0, "StickLocalPos")
    self:NetworkVar("Angle", 0, "StickLocalAng")
end

local function StickToBone(self, ent, hitpos, hitnormal)
    local bone = ent:GetHitBoxBone(0, 0) or 0

    -- fallback: nearest bone search
    if bone == 0 then
        local best = 0
        local bestDist = math.huge
        for i = 0, ent:GetBoneCount() - 1 do
            local bp = ent:GetBonePosition(i)
            if bp then
                local d = bp:DistToSqr(hitpos)
                if d < bestDist then
                    bestDist = d
                    best = i
                end
            end
        end
        bone = best
    end

    local bonePos, boneAng = ent:GetBonePosition(bone)
    if not bonePos then bonePos, boneAng = ent:GetPos(), ent:GetAngles() end

    local localPos, localAng = WorldToLocal(hitpos, hitnormal:Angle(), bonePos, boneAng)

    self:SetStickEntity(ent)
    self:SetStickBone(bone)
    self:SetStickLocalPos(localPos)
    self:SetStickLocalAng(localAng)

    -- DEFER collision disabling to avoid warnings
    timer.Simple(0, function()
        if not IsValid(self) then return end
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
    end)
end

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/weapons/w_models/w_syringe_proj.mdl")
		
		local mins = Vector(-1, -1, -1)
		local maxs = Vector(1, 1, 1)
        self:PhysicsInitBox(mins, maxs)
		
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_BBOX)
		self:SetCollisionBounds(mins, maxs)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
			phys:SetMass(1)
			phys:EnableGravity(true)
			phys:EnableDrag(true)
        end
		
		-- get the weapon that fired the syringe
		local attacker = self:GetOwner()
		self.Weapon = attacker.GetActiveWeapon and attacker:GetActiveWeapon()
		self.DmgAmount = self.Weapon.Primary.Damage
    end
end

function ENT:PhysicsCollide(data, phys)
	if self.HasAppliedDamage then return end
	
    local hit = data.HitEntity
    local owner = self:GetOwner()
    local pos = data.HitPos
    local normal = data.HitNormal
	
	-- apply damage
    if IsValid(hit) and hit ~= owner then
		self.HasAppliedDamage = true
		self:ApplyDamage(hit, pos)
	end

    -- world
    if hit:IsWorld() then
		local hitpos = pos
		local hitang = self:GetAngles()

		timer.Simple(0, function()
			if not IsValid(self) then return end

			-- apply transform AFTER callback
			self:SetPos(hitpos)
			self:SetAngles(hitang)

			-- freeze physics safely
			local phys = self:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(false)
			end

			self:SetMoveType(MOVETYPE_NONE)
			self:SetSolid(SOLID_NONE)
		end)
	end


    -- NPC / player
	if hit:Alive() then
		StickToBone(self, hit, pos, normal)
    end
	
	-- remove after time
	timer.Simple(5, function()
		if IsValid(self) then
			self:Remove()
		end
	end)
end

function ENT:Draw()
    local ent = self:GetStickEntity()
    if IsValid(ent) then
        local bone = self:GetStickBone()
        local bonePos, boneAng = ent:GetBonePosition(bone)

        if bonePos then
            local pos, ang = LocalToWorld(
                self:GetStickLocalPos(),
                self:GetStickLocalAng(),
                bonePos,
                boneAng
            )
            self:SetPos(pos)
            self:SetAngles(ang)
        end
    end

    self:DrawModel()
end

if SERVER then
    function ENT:Think()
        local ent = self:GetStickEntity()
		
        -- npc / player died
        if (ent:IsNPC() or ent:IsPlayer()) and not ent:Alive() then
            self:Remove()
            return
        end
    end
	
	function ENT:ApplyDamage(hit, hitpos)
		if not IsValid(hit) then return end
		
		if not hit:IsNPC() and not hit:IsPlayer() then return end
		
		local owner = self:GetOwner()
		if not IsValid(owner) then owner = self end

		-- get the weapon that fired the syringe
		local wep = self.Weapon
		local dmgAmount = self.DmgAmount
		local isMiniCrit = false
		local isFullCrit = false

		-- modify the damage
		if IsValid(wep) and wep.ModifyDamage then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(dmgAmount)
			
			local fakeTr = {
				Entity = hit,
				HitPos = hitpos,
				HitNormal = Vector(0,0,1)
			}

			dmgAmount, isMiniCrit, isFullCrit = wep:ModifyDamage(owner, fakeTr, dmginfo)
			
			-- increase damage based on crits
			if isFullCrit then
				dmgAmount = dmgAmount * 3
			elseif isMiniCrit then
				dmgAmount = dmgAmount * 1.35
			end
		end

		-- build damageinfo
		local dmg = DamageInfo()
		dmg:SetDamage(dmgAmount)
		dmg:SetAttacker(owner)
		dmg:SetInflictor(self)
		dmg:SetDamageType(DMG_BULLET)
		dmg:SetDamagePosition(hitpos)
		dmg:SetDamageForce(self:GetVelocity() * 50)

		hit:TakeDamageInfo(dmg)
		
		-- perform a magic extra effect
		wep:ExtraEffectOnHit(owner, hit)
		
		-- add time of hit for the damage numbers hook (trust me)
		hit._MW_LastHit = {attacker = owner, crit = isFullCrit and 2 or (isMiniCrit and 1 or 0), timeHit = CurTime()}
		
		-- send damage sound
		if SERVER and IsValid(owner) and owner:IsPlayer() then
			net.Start("mw_damage_sound")
			net.WriteUInt(isFullCrit and 2 or (isMiniCrit and 1 or 0), 2)
			net.Send(owner)
		end
	end
end
