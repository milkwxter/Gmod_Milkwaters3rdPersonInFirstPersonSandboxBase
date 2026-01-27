if CLIENT then
	-- cache
	local headBones = {}
	
	-- fallback so autorun doesn't error before shared files load
	local function MW_GetFPCamera(ply)
		ply:SetupBones()
		local head = ply:LookupBone("ValveBiped.Bip01_Head1")
		if head then
			local matrix = ply:GetBoneMatrix(head)
			local pos = matrix:GetTranslation()
			local ang = matrix:GetAngles()
			
			if pos and ang then
				return pos + ang:Forward() * -2 + ang:Up() * 2, ang
			end
		end

		return ply:EyePos(), ply:EyeAngles()
	end

	-- helper to see if using my weapons
    local function Using3PBase(ply)
        local wep = ply:GetActiveWeapon()
        return IsValid(wep) and wep.Base == "milkwaters_3p_base"
    end
	
	-- hide viewmodel
    hook.Add("PreDrawViewModel", "mw_3p_hide_vm", function(vm, ply, wep)
        if Using3PBase(ply) then
            return true
        end
    end)
	
	-- draw body in first person
    hook.Add("ShouldDrawLocalPlayer", "mw_3p_draw_body", function(ply)
        if Using3PBase(ply) then
            return true
        end
    end)
	
	hook.Add("CalcView", "mw_3p_calcview", function(ply, pos, ang, fov)
		if not Using3PBase(ply) then return end
		if ply ~= LocalPlayer() then return end

		local cpos = MW_GetFPCamera(ply)
		local cang = ply:EyeAngles()

		return {
			origin = cpos,
			angles = cang,
			fov = fov,
			drawviewer = true,
		}
	end)

	hook.Add("PostPlayerDraw", "mw_3p_hide_head", function(ply)
		if not Using3PBase(ply) then return end

		local head = ply:LookupBone("ValveBiped.Bip01_Head1")
		if head then
			ply:ManipulateBoneScale(head, Vector(0,0,0))
		end
	end)

end
