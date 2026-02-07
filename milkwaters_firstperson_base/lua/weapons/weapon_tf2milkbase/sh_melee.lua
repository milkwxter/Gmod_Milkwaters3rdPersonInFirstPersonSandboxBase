-- sh_melee.lua
function SWEP:DoMeleeAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- play swing effects
    owner:EmitSound(self.MeleeSwingSound)
	owner:SetAnimation(PLAYER_ATTACK1)

    timer.Simple(self.MeleeDelay, function()
        if not IsValid(self) or not IsValid(owner) then return end
        self:DoMeleeTrace()
    end)
end

function SWEP:DoMeleeTrace()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local startPos = MW_GetFPCamera(owner)
    local endPos = startPos + owner:GetAimVector() * self.MeleeRange

    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        filter = owner,
        mins = Vector(-1, -1, -1),
        maxs = Vector(1, 1, 1),
        mask = MASK_SHOT
    })

    if not tr.Hit then return end

	local hit = tr.Entity

    local damage = self.MeleeDamage
    local isMiniCrit, isFullCrit = false, false
	
	-- bullet for effects and damage
	if SERVER then
		local dir = (tr.HitPos - owner:GetShootPos()):GetNormalized()

		local bullet = {}
		bullet.Num      = 1
		bullet.Src      = owner:GetShootPos()
		bullet.Dir      = dir
		bullet.Spread   = Vector(0, 0, 0)
		bullet.Tracer   = 0
		bullet.HullSize = 2
		bullet.Force    = damage * 0.5
		bullet.Damage   = damage
		bullet.Distance = self.MeleeRange + 32
		
		bullet.Callback = function(att, tr, dmginfo)
			if CLIENT and not IsFirstTimePredicted() then return end

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
	end

    -- hit sound
    owner:EmitSound(self.MeleeHitSound)
	
	-- add time of hit for the damage numbers hook (trust me)
	hit._MW_LastHit = {attacker = owner, crit = isFullCrit and 2 or (isMiniCrit and 1 or 0), timeHit = CurTime()}
	
	-- send damage sound
	if SERVER and IsValid(owner) and owner:IsPlayer() then
		net.Start("mw_damage_sound")
		net.WriteUInt(isFullCrit and 2 or (isMiniCrit and 1 or 0), 2)
		net.Send(owner)
	end

    -- custom effect hook
    self:ExtraEffectOnHit(owner, tr)
end