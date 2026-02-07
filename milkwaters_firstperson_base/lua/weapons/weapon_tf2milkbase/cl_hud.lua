-- cl_hud.lua
if CLIENT then
	net.Receive("mw_name_popup", function()
		LocalPlayer().NamePopupEndTime = net.ReadFloat()
	end)

	-- helper to see if using my weapons
	local function Using3PBase(ply)
		if not IsValid(ply) then return false end
		local wep = ply:GetActiveWeapon()
		return IsValid(wep) and wep.Base == "weapon_tf2milkbase"
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

		-- weapon name popup + desc
		if now < endTime then
			local duration = endTime - (endTime - 2)
			local remaining = endTime - now
			local frac = math.Clamp(remaining / duration, 0, 1)
			local alpha = frac * 255

			local baseX = x
			local baseY = y * 0.5
			local spacing = 40

			draw.SimpleTextOutlined(
				self.PrintName,
				"MW_TF2Damage",
				baseX,
				baseY,
				Color(247, 229, 198, alpha),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER,
				2,
				Color(55, 51, 49, alpha)
			)

			draw.SimpleTextOutlined(
				self.Purpose,
				"MW_TF2Damage_Small",
				baseX,
				baseY + spacing,
				Color(247, 229, 198, alpha),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER,
				1,
				Color(55, 51, 49, alpha)
			)
		end

		-- ammo + crosshair display
		self:DrawCrosshairHUD(x, y)
		self:DrawAmmoArc(x + 50, y)
		
		-- health display
		self:DrawHealthHUD(400, ScrH() - 200)
		
		-- ammo display
		do
			local clip = self:Clip1()
			local reserve = owner:GetAmmoCount(self.Primary.Ammo)
			local text = clip .. " / " .. reserve
			
			local ammoColor = Color(247, 229, 198, 255)
			if clip <= 0 then
				ammoColor = Color(255, 0, 0, 255)
			end

			draw.SimpleTextOutlined(
				text,
				"MW_TF2Damage_Large",
				ScrW() - 400,
				ScrH() - 100,
				ammoColor,
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
		local clipMax  = self.Primary.ClipSize
		if clipMax <= 0 then return end
		
		local minThickness = 3
		local maxThickness = 22

		-- scale thickness
		local thickness = Lerp( math.Clamp(clipMax / 30, 0, 1), maxThickness, minThickness )

		local tickLength = 12
		local innerRadius = 50
		local outerRadius = innerRadius + tickLength
		
		local arcSize = 135
		
		local arcStart = -arcSize * 0.5
		local arcEnd =  arcSize * 0.5
		
		local tickArc = arcSize / clipMax

		local tickCount = clipMax
		
		local maxSpacing = 10
		local minimumTickSpacing = 0.2
		if clipMax > 40 then
			minimumTickSpacing = 0
		end
		
		local spacingFrac = math.Clamp((41 - tickCount) / 41, minimumTickSpacing, 1)
		local spacing = maxSpacing * spacingFrac

		local totalSpacing = (tickCount - 1) * spacing

		local usableArc = arcSize - totalSpacing
		local tickFill = usableArc / tickCount

		for i = 1, clipMax do
			local startAng = arcStart + (i - 1) * (tickFill + spacing)
			local endAng   = startAng + tickFill

			local color
			if i <= clip then
				color = Color(247, 229, 198, 255)
			else
				color = Color(247, 229, 198, 40)
			end

			drawDonutSlice(x, y, innerRadius, outerRadius, startAng, endAng, nil, color)
		end
	end

	function SWEP:DrawCrosshairHUD(x, y)
		local pink = Color(0, 255, 0)
		surface.DrawCircle(x, y, 4, pink)
		surface.DrawCircle(x, y, 5, pink)
	end

	function SWEP:DrawSniperScope()
		DrawMaterialOverlay( "hud/scope_sniper_ul", -0.1 )
	end

	function SWEP:DrawSniperCharge()
		local frac = self:GetZoomChargeProgress()
		local w, h = ScrW(), ScrH()
		local barW = w * 0.3
		local barH = 12
		local x = (w - barW) * 0.5
		local y = h * 0.8
		local zoomColor = Color(234, 192, 124, 255)
		
		-- background
		surface.SetDrawColor(0, 0, 0, 180)
		surface.DrawRect(x, y, barW, barH)
		
		-- fill
		surface.SetDrawColor(zoomColor)
		surface.DrawRect(x, y, barW * frac, barH)
		
		-- text
		draw.SimpleTextOutlined(
			"Charge Progress",
			"MW_TF2Damage",
			w / 2,
			y - 20,
			zoomColor,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER,
			2,
			Color(55, 51, 49, alpha)
		)
	end
end