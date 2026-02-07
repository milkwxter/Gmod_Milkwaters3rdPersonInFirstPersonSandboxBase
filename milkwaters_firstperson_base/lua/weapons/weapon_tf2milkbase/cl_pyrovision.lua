-- cl_pyrovision.lua
if CLIENT then
	local pyroBorder = Material("hud/pyro_pink_border01")
	
	local colourParameters = {
		["$pp_colour_addr"] = 0,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = 0.1,
		["$pp_colour_contrast"] = 1,
		["$pp_colour_colour"] = 1.5,
		["$pp_colour_mulr"] = 0,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0
	}
	
	function SWEP:DrawHUDPyrovision()
        if not pyroBorder then return end

        local w, h = ScrW(), ScrH()

        surface.SetMaterial(pyroBorder)
        surface.SetDrawColor(255, 209, 255)

        -- fullscreen overlay
        surface.DrawTexturedRectRotated(ScrW() / 2, ScrH() / 2, ScrW(), ScrH(), 0)
        surface.DrawTexturedRectRotated(ScrW() / 2, ScrH() / 2, ScrW(), ScrH(), 180)
    end

	hook.Add("RenderScreenspaceEffects", "MW_RenderPyrovision", function()
		local ply = LocalPlayer()
		if not ply then return end
		
		local wep = ply:GetActiveWeapon()
		if not wep.EnablePyroland then return end
		
		DrawColorModify(colourParameters)
	end)
end