local dmgNums = {}

net.Receive("mw_damage_number", function()
    local dmg = net.ReadFloat()
    local pos = net.ReadVector()
    local entIndex = net.ReadUInt(16)

    local now = CurTime()
    local existing = dmgNums[entIndex]

    if existing then
        existing.dmg = existing.dmg + math.floor(dmg)
        existing.pos = pos
        existing.start = now
        existing.life = 1.0
        existing.xoff = math.Rand(-10, 10)
        existing.yoff = math.Rand(-5, -15)
    else
        dmgNums[entIndex] = {
            dmg = math.floor(dmg),
            pos = pos,
            start = now,
            life = 1.0,
            xoff = math.Rand(-10, 10),
            yoff = math.Rand(-5, -15)
        }
    end
end)

hook.Add("HUDPaint", "mw_draw_damage_numbers", function()
    local now = CurTime()

    for entIndex, d in pairs(dmgNums) do
        local t = (now - d.start) / d.life

        if t >= 1 then
            dmgNums[entIndex] = nil
        else
            local screen = d.pos:ToScreen()
            local alpha = 255 * (1 - t)

            local y = screen.y + d.yoff * t
            local x = screen.x + d.xoff * t

            draw.SimpleText(
                "-" .. d.dmg,
                "MW_TF2Damage",
                x,
                y,
                Color(0, 255, 0, alpha),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end
    end
end)

surface.CreateFont("MW_TF2Damage", {
    font = "TF2",
    size = 32,
    weight = 500,
    antialias = true,
    additive = false
})
