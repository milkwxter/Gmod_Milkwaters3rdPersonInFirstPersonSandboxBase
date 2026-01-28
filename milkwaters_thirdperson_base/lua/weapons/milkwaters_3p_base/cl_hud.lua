net.Receive("mw_name_popup", function()
    LocalPlayer().NamePopupEndTime = net.ReadFloat()
end)

-- helper to see if using my weapons
local function Using3PBase(ply)
	if not IsValid(ply) then return false end
    local wep = ply:GetActiveWeapon()
    return IsValid(wep) and wep.Base == "milkwaters_3p_base"
end

hook.Add("HUDShouldDraw", "HideDefaultHealth", function(name)
	if not Using3PBase(LocalPlayer()) then
        return true
    end
	
    if name == "CHudHealth" or name == "CHudBattery" then
        return false
    end
end)

function SWEP:DrawHUD()
    local owner = LocalPlayer()
    if not IsValid(owner) then return end

    local x = ScrW() * 0.5
    local y = ScrH() * 0.5

    local endTime = LocalPlayer().NamePopupEndTime or 0
    local now = CurTime()

    if now < endTime then
        local duration = endTime - (endTime - 2)
        local remaining = endTime - now
        local frac = math.Clamp(remaining / duration, 0, 1)
        local alpha = frac * 255

        draw.SimpleText(
            self.PrintName,
            "MW_TF2Damage",
            x,
            y * 0.5,
            Color(255, 255, 255, alpha),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    self:DrawCrosshairHUD(x, y)
    self:DrawAmmoArc(x + 50, y)
	
	-- health display
	self:DrawHealthHUD(400, ScrH() - 200)
	
	-- ammo display
	do
		local clip = self:Clip1()
		local reserve = owner:GetAmmoCount(self.Primary.Ammo)
		local text = clip .. " / " .. reserve

		draw.SimpleTextOutlined(
			text,
			"MW_TF2Damage_Large",
			ScrW() - 400,
			ScrH() - 100,
			Color(247, 229, 198, 255),
			TEXT_ALIGN_RIGHT,
			TEXT_ALIGN_BOTTOM,
			3,
			Color(55, 51, 49, 255)
		)
	end
end

function SWEP:DrawHealthHUD(x, y)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local hp = math.max(ply:Health(), 0)
    local maxhp = ply:GetMaxHealth() or 100

    local frac = math.Clamp(hp / maxhp, 0, 1)

    -- base geometry
	local armLength = 100
	local thickness = 75
	
	-- danger pulse
	if frac <= 0.5 then
		local pulse = math.abs(math.sin(CurTime() * 8))
		local alpha = pulse * 150

		local danger = 1 - frac
		local extra = (danger * 20) + (pulse * danger * 15)

		local pulseArmLength = armLength + extra
		local pulseThickness = thickness + extra
		
		surface.SetDrawColor(200, 0, 0, alpha)
		surface.DrawRect(x - pulseThickness * 0.5, y - pulseArmLength, pulseThickness, pulseArmLength * 2)
		surface.DrawRect(x - pulseArmLength, y - pulseThickness * 0.5, pulseArmLength * 2, pulseThickness)
	end

    -- background cross
	surface.SetDrawColor(55, 51, 49, 255)
	surface.DrawRect(x - thickness * 0.5, y - armLength, thickness, armLength * 2)
	surface.DrawRect(x - armLength, y - thickness * 0.5, armLength * 2, thickness)

    -- fill color
	local startColor = Color(247, 229, 198, 255)
	local endColor = Color(200, 0, 0, 255)
	local r = startColor.r + (endColor.r - startColor.r) * (1 - frac)
	local g = startColor.g + (endColor.g - startColor.g) * (1 - frac)
	local b = startColor.b + (endColor.b - startColor.b) * (1 - frac)
	local fillColor = Color(r, g, b, 255)
	surface.SetDrawColor(fillColor)
	
	-- inner geometry
	thickness = thickness - (armLength * 0.1)
	armLength = armLength - (thickness * 0.1)

    -- vertical fill
	local totalV = armLength * 2
	local vHeight = totalV * frac
	surface.DrawRect( x - thickness * 0.5, (y - armLength) + (totalV - vHeight), thickness, vHeight )
	
    -- horizontal fill
	local vTop = y - armLength
	local vBottom = y + armLength
	local hTop = y - thickness * 0.5
	local hBottom = y + thickness * 0.5
	local fillY = vBottom - vHeight
	local hFrac
	if fillY <= hTop then
		hFrac = 1
	elseif fillY >= hBottom then
		hFrac = 0
	else
		hFrac = 1 - ((fillY - hTop) / (hBottom - hTop))
	end
	
	local hHeight = thickness * hFrac
	surface.DrawRect( x - armLength, hBottom - hHeight, armLength * 2, hHeight )
	
	-- text
    draw.SimpleText(
        tostring(hp),
        "MW_TF2Damage_Large",
		x,
		y,
        Color(118, 107, 94, 255),
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER
    )
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
			color = Color(247, 229, 198, 255)
		else
			color = Color(247, 229, 198, 40)
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

function SWEP:DrawCrosshairHUD(x, y)
	local cone = self.Cone

	local baseGap = math.max(0.2, 100 * cone)
	local coneGap = cone * 300
	local gap = baseGap + coneGap

	local length = 8
	local thickness = 1
	
	surface.SetDrawColor(255, 255, 255, 255)

	draw.NoTexture()

	-- left
	surface.DrawPoly({
		{x = x - gap - length, y = y - thickness},
		{x = x - gap,          y = y - thickness},
		{x = x - gap,          y = y + thickness},
		{x = x - gap - length, y = y + thickness},
	})

	-- right
	surface.DrawPoly({
		{x = x + gap,          y = y - thickness},
		{x = x + gap + length, y = y - thickness},
		{x = x + gap + length, y = y + thickness},
		{x = x + gap,          y = y + thickness},
	})

	-- top
	surface.DrawPoly({
		{x = x - thickness, y = y - gap - length},
		{x = x + thickness, y = y - gap - length},
		{x = x + thickness, y = y - gap},
		{x = x - thickness, y = y - gap},
	})

	-- bottom
	surface.DrawPoly({
		{x = x - thickness, y = y + gap},
		{x = x + thickness, y = y + gap},
		{x = x + thickness, y = y + gap + length},
		{x = x - thickness, y = y + gap + length},
	})
end