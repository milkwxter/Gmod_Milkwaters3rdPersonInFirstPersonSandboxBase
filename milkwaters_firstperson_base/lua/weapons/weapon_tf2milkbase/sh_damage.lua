-- global modify damage function, please call this in custom weapons to ease your burden
function SWEP:ModifyDamage(att, tr, dmginfo)
    local hit = tr.Entity
    local dmg = dmginfo:GetDamage()
	
    local isMiniCrit = false
	local isFullCrit = false

    -- minicrits if the target is jarated
    if IsValid(hit) and hit._JarateTimer then
        isMiniCrit = true
    end
	
    return dmg, isMiniCrit, isFullCrit
end

function SWEP:ExtraEffectOnHit(att, tr)
	-- call me in the child weapon
end

function SWEP:ExtraEffectOnShoot()
	-- add logic here in child weapons
end

-- stop hitgroups for players
hook.Add("ScalePlayerDamage", "mw_disable_hitgroups_player", function(ply, hitgroup, dmginfo)
	local attacker = dmginfo:GetAttacker()
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	
	local wep = attacker:GetActiveWeapon()
	if not IsValid(wep) then return end
	
    -- remove all hitgroup scaling for my guns
	if wep.Base == "weapon_tf2milkbase" then
		return false
	end
end)

-- stop hitgroups for npcs
hook.Add("ScaleNPCDamage", "mw_disable_hitgroups_npc", function(ply, hitgroup, dmginfo)
	local attacker = dmginfo:GetAttacker()
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	
	local wep = attacker:GetActiveWeapon()
	if not IsValid(wep) then return end
	
    -- remove all hitgroup scaling for my guns
	if wep.Base == "weapon_tf2milkbase" then
		return false
	end
end)

-- damage numbers hook
hook.Add("EntityTakeDamage", "mw_damage_numbers", function(ent, dmginfo)
    local tag = ent._MW_LastHit
    if not tag then return end
    if tag.timeHit < CurTime() - 0.1 then return end

    local att = tag.attacker
    if not (IsValid(att) and att:IsPlayer()) then return end
	
	if not ent:Alive() then return end

    net.Start("mw_damage_number")
    net.WriteFloat(dmginfo:GetDamage())
    net.WriteVector(ent:WorldSpaceCenter())
    net.WriteUInt(ent:EntIndex(), 16)
    net.WriteUInt(tag.crit, 2)
    net.Send(att)

    ent._MW_LastHit = nil
end)