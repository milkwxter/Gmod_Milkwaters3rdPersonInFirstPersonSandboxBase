function SWEP:DrawHUD()
	local owner = LocalPlayer()
	if not IsValid(owner) then return end

	local x = ScrW() * 0.5
	local y = ScrH() * 0.5
	
	-- draw ammo arc
	self:DrawAmmoArc(x + 50, y)
end

-- draw a crazy tesselated slice with convex quads
local function drawDonutSlice(centerX, centerY, innerRadius, outerRadius, startAngle, endAngle, segments, color)
	local arcLen = math.rad(endAngle - startAngle) * innerRadius
	local pixelsPerSegment = 6
	segments = math.max(segments or 0, math.ceil(arcLen / pixelsPerSegment))

	surface.SetDrawColor(color)
	draw.NoTexture()

	for i = 0, segments - 1 do
		local t0 = i / segments
		local t1 = (i + 1) / segments

		local a0 = math.rad(startAngle + t0 * (endAngle - startAngle))
		local a1 = math.rad(startAngle + t1 * (endAngle - startAngle))

		local ox0 = centerX + math.cos(a0) * outerRadius
		local oy0 = centerY + math.sin(a0) * outerRadius
		local ox1 = centerX + math.cos(a1) * outerRadius
		local oy1 = centerY + math.sin(a1) * outerRadius

		local ix0 = centerX + math.cos(a0) * innerRadius
		local iy0 = centerY + math.sin(a0) * innerRadius
		local ix1 = centerX + math.cos(a1) * innerRadius
		local iy1 = centerY + math.sin(a1) * innerRadius
		
		surface.DrawPoly({
			{ x = ox0, y = oy0 },
			{ x = ox1, y = oy1 },
			{ x = ix1, y = iy1 },
			{ x = ix0, y = iy0 },
		})
	end
end

function SWEP:DrawAmmoArc(x, y)
	local owner = LocalPlayer()
	if not IsValid(owner) then return end

	local clip = self:Clip1()
	local max  = self.Primary.ClipSize
	if max <= 0 then return end
	
	local minThickness = 3
	local maxThickness = 22

	-- scale thickness
	local thickness = Lerp( math.Clamp(max / 30, 0, 1), maxThickness, minThickness )

	local tickLength = 12
	local innerRadius = 50
	local outerRadius = innerRadius + tickLength
	
	local arcSize = 120

	-- center the arc around 0°
	local arcStart = -arcSize * 0.5
	local arcEnd =  arcSize * 0.5
	
	local tickArc = arcSize / max
	local tickSpacing = tickArc * 0.5
	local tickFill = tickArc - tickSpacing

	for i = 1, max do
		local startAng = arcStart + (i - 1) * tickArc
		local endAng   = startAng + tickFill

		local color
		if i <= clip then
			color = Color(255, 255, 255, 255)
		else
			color = Color(255, 255, 255, 40)
		end

		drawDonutSlice(
			x, y,
			innerRadius,
			outerRadius,
			startAng,
			endAng,
			nil,
			color
		)
	end
end