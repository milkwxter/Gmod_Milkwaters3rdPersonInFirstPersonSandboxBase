-- cl_damage_numbers.lua
if CLIENT then
	local dmgNums = {}

	net.Receive("mw_damage_number", function()
		local dmg = net.ReadFloat()
		local pos = net.ReadVector()
		local entIndex = net.ReadUInt(16)
		local critState = net.ReadUInt(2) -- 0 normal, 1 mini, 2 full

		local now = CurTime()
		local existing = dmgNums[entIndex]

		if existing then
			existing.dmg = existing.dmg + math.floor(dmg)
			existing.pos = pos
			existing.start = now
			existing.life = 1.0
			existing.xoff = math.Rand(-10, 10)
			existing.yoff = math.Rand(-5, -15)
			existing.critState = critState
		else
			dmgNums[entIndex] = {
				dmg = math.floor(dmg),
				pos = pos,
				start = now,
				life = 1.0,
				xoff = math.Rand(-10, 10),
				yoff = math.Rand(-5, -15),
				critState = critState
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

				-- choose color based on crit type
				local crit = d.critState
				local textColor

				if crit == 2 then
					textColor = Color(0, 255, 0, alpha)
				elseif crit == 1 then
					textColor = Color(255, 255, 0, alpha)
				else
					textColor = Color(255, 0, 0, alpha)
				end

				-- crit text
				if crit == 2 then
					draw.SimpleText(
						"CRIT!",
						"MW_TF2Damage",
						x,
						y - 30,
						textColor,
						TEXT_ALIGN_CENTER,
						TEXT_ALIGN_CENTER
					)
				elseif crit == 1 then
					draw.SimpleText(
						"MINI CRIT!",
						"MW_TF2Damage",
						x,
						y - 30,
						textColor,
						TEXT_ALIGN_CENTER,
						TEXT_ALIGN_CENTER
					)
				end

				-- damage number
				draw.SimpleText(
					"-" .. d.dmg,
					"MW_TF2Damage",
					x,
					y,
					textColor,
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

	surface.CreateFont("MW_TF2Damage_Small", {
		font = "TF2",
		size = 16,
		weight = 500,
		antialias = true,
		additive = false
	})
	surface.CreateFont("MW_TF2Damage_Large", {
		font = "TF2",
		size = 64,
		weight = 500,
		antialias = true,
		additive = false
	})
end