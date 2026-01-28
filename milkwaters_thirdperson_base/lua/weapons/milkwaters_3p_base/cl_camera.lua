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
	if not IsValid(ply) then return false end
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

-- view roll
local viewRoll     = 0
local viewRollVel  = 0
local rollStrength = 0.02

-- capture mouse movement
hook.Add("CreateMove", "mw_3p_roll_input", function(cmd)
    if not Using3PBase(LocalPlayer()) then return end

    local mx = cmd:GetMouseX()
    viewRollVel = viewRollVel + mx * rollStrength
end)

local stiffness = 120
local damping = 14

hook.Add("Think", "mw_3p_roll_update", function()
    if not Using3PBase(LocalPlayer()) then return end

    local ft = FrameTime()

    -- spring force pulling roll back to zero
    local force = -stiffness * viewRoll

    -- apply damping
    force = force - damping * viewRollVel

    -- integrate velocity + position
    viewRollVel = viewRollVel + force * ft
    viewRoll    = viewRoll + viewRollVel * ft
end)

hook.Add("CalcView", "mw_3p_calcview", function(ply, pos, ang, fov)
    if not Using3PBase(ply) then return end
    if ply ~= LocalPlayer() then return end

    local cang = ply:EyeAngles()
    local cpos = MW_GetFPCamera(ply) + cang:Forward() * 2 + cang:Up() * 2

    -- apply recoil
    cang:Add(mw_recoil)

    -- apply view roll
    cang.r = cang.r + viewRoll

    -- decay recoil
    mw_recoil.p = mw_recoil.p * 0.9
    mw_recoil.y = mw_recoil.y * 0.9

    return {
        origin = cpos,
        angles = cang,
        fov = fov,
        drawviewer = true,
    }
end)

-- hide head
hook.Add("PostPlayerDraw", "mw_3p_hide_head", function(ply)
    if not Using3PBase(ply) then return end

    local head = ply:LookupBone("ValveBiped.Bip01_Head1")
    if head then
        ply:ManipulateBoneScale(head, Vector(0,0,0))
    end
end)
