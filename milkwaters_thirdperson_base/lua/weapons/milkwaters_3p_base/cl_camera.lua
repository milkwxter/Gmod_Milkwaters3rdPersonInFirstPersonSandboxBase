-- cl_camera.lua
if CLIENT then
    -- recoil accumulator
    local mw_recoil = Angle(0, 0, 0)

    function MW_AddRecoil(p, y)
        mw_recoil.p = mw_recoil.p + p
        mw_recoil.y = mw_recoil.y + y
    end
	
    -- helper
    local function Using3PBase(ply)
        if not IsValid(ply) then return false end
        local wep = ply:GetActiveWeapon()
        return IsValid(wep) and wep.Base == "milkwaters_3p_base"
    end
	
    -- hide viewmodel
    hook.Add("PreDrawViewModel", "mw_3p_hide_vm", function(vm, ply)
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
	
    -- view roll system
    local viewRoll    = 0
    local viewRollVel = 0

    local rollStrength = 0.02
    local stiffness    = 120
    local damping      = 14

    -- capture mouse movement
    hook.Add("CreateMove", "mw_3p_roll_input", function(cmd)
        if not Using3PBase(LocalPlayer()) then return end
        viewRollVel = viewRollVel + cmd:GetMouseX() * rollStrength
    end)

    -- spring update
    hook.Add("Think", "mw_3p_roll_update", function()
        if not Using3PBase(LocalPlayer()) then return end

        local ft = FrameTime()

        -- spring force
        local force = -stiffness * viewRoll
        force = force - damping * viewRollVel

        -- integrate
        viewRollVel = viewRollVel + force * ft
        viewRoll    = viewRoll    + viewRollVel * ft
    end)
	
    -- main camera override
    hook.Add("CalcView", "mw_3p_calcview", function(ply, pos, ang, fov)
        if ply ~= LocalPlayer() then return end
        if not Using3PBase(ply) then return end

        local cang = ply:EyeAngles()
        local cpos = MW_GetFPCamera(ply)
            + cang:Forward() * 2
            + cang:Up()      * 2

        -- apply recoil
        cang:Add(mw_recoil)

        -- apply roll
        cang.r = cang.r + viewRoll

        -- decay recoil
        mw_recoil.p = mw_recoil.p * 0.9
        mw_recoil.y = mw_recoil.y * 0.9

        return {
            origin      = cpos,
            angles      = cang,
            fov         = fov,
            drawviewer  = true,
        }
    end)
	
    -- hide head bone
    hook.Add("PostPlayerDraw", "mw_3p_hide_head", function(ply)
        if not Using3PBase(ply) then return end

        local head = ply:LookupBone("ValveBiped.Bip01_Head1")
        if head then
            ply:ManipulateBoneScale(head, vector_origin)
        end
    end)

end
