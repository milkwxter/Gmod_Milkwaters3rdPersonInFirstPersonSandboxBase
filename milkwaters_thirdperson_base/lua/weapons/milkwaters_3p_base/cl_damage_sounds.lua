if CLIENT then
    net.Receive("mw_damage_sound", function()
        local isMiniCrit = net.ReadBool()

        if isMiniCrit then
            surface.PlaySound("ui/hitsound.wav")
        end
    end)
end