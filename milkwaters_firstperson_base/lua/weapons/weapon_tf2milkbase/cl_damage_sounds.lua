-- cl_damage_sounds.lua
if CLIENT then
    net.Receive("mw_damage_sound", function()
        local critState = net.ReadUInt(2)  -- 0 normal, 1 mini, 2 full

        if critState == 2 then
            surface.PlaySound("crit_hit.wav")
        elseif critState == 1 then
            surface.PlaySound("ui/hitsound.wav")
		else
			surface.PlaySound("phx/eggcrack.wav")
        end
    end)
end
