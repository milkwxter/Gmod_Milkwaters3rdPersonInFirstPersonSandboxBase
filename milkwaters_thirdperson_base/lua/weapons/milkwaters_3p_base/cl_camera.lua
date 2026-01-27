-- cl_camera.lua

-- cache
local headBones = {}

-- recoil
local mw_recoil = Angle(0, 0, 0)
function MW_AddRecoil(p, y)
	mw_recoil.p = mw_recoil.p + p
	mw_recoil.y = mw_recoil.y + y
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

	local cang = ply:EyeAngles()
	local cpos = MW_GetFPCamera(ply) + cang:Forward() * 2
	
	-- apply recoil
	cang:Add(mw_recoil)
	
	-- decay recoil over time
	mw_recoil.p = mw_recoil.p * 0.9
	mw_recoil.y = mw_recoil.y * 0.9

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
