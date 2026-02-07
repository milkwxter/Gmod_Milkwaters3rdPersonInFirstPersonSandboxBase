-- cl_sniper_dot.lua
if CLIENT then
    local dotMat = Material("effects/sniperdot")

    hook.Add("PostDrawOpaqueRenderables", "MW_DrawSniperDots", function()
        for _, ply in ipairs(player.GetAll()) do
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and wep.CanZoom and wep:GetZoomed() then
                local pos = wep:GetZoomDotPos()
                if pos and pos ~= vector_origin then
                    render.SetMaterial(dotMat)
                    render.DrawSprite(pos, 8, 8, Color(255, 0, 0))
                end
            end
        end
    end)
end
