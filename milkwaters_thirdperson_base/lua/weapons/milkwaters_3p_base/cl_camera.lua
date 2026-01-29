if CLIENT then
	-- my helper
	local function Using3PBase(ply)
		if not IsValid(ply) then return false end
		local wep = ply:GetActiveWeapon()
		return IsValid(wep) and wep.Base == "milkwaters_3p_base"
	end

	-- smoothed camera angle
	local camAng = Angle(0,0,0)

	-- recoil spring
	local recoil = Angle(0,0,0)
	local recoilVel = Angle(0,0,0)

	-- roll spring
	local roll = 0
	local rollVel = 0

	-- spring tuning
	local recoilFreq = 12     -- higher = snappier
	local rollFreq   = 10
	local damping    = 1      -- critically damped

	function MW_AddRecoil(p, y)
		recoil.p = recoil.p + p
		recoil.y = recoil.y + y
	end

	local function SpringUpdate(x, v, freq, dt)
		local w = freq * 2 * math.pi
		local f = -2 * damping * w * v - (w*w) * x
		v = v + f * dt
		x = x + v * dt
		return x, v
	end
	
	local function CameraCollision(ply, desiredPos, camAng)
		local head = ply:EyePos()

		local tr = util.TraceHull({
			start  = head,
			endpos = desiredPos,
			mins   = Vector(-4, -4, -4),
			maxs   = Vector( 4,  4,  4),
			filter = ply,
			mask   = MASK_SOLID_BRUSHONLY
		})

		if tr.Hit then
			return tr.HitPos + tr.HitNormal * 2
		end

		return desiredPos
	end

	hook.Add("CalcView", "mw_3p_calcview", function(ply, pos, ang, fov)
		if ply ~= LocalPlayer() then return end
		if not Using3PBase(ply) then return end

		local dt = FrameTime()

		-- smooth base angle
		local target = ply:EyeAngles()
		camAng.p = camAng.p + math.AngleDifference(target.p, camAng.p) * dt * 15
		camAng.y = camAng.y + math.AngleDifference(target.y, camAng.y) * dt * 15
		camAng.r = camAng.r + math.AngleDifference(target.r, camAng.r) * dt * 15

		-- recoil spring
		recoil.p, recoilVel.p = SpringUpdate(recoil.p, recoilVel.p, recoilFreq, dt)
		recoil.y, recoilVel.y = SpringUpdate(recoil.y, recoilVel.y, recoilFreq, dt)

		-- roll based on yaw velocity
		local yawDelta = math.AngleDifference(target.y, camAng.y)
		rollVel = rollVel + yawDelta * 0.02
		roll, rollVel = SpringUpdate(roll, rollVel, rollFreq, dt)

		-- final camera angle
		local cang = camAng + recoil
		cang.r = cang.r + roll

		-- camera position
		local offset = cang:Forward() * 6 + cang:Up() * 4
		local cpos = MW_GetFPCamera(ply) + offset
		
		cpos = CameraCollision(ply, cpos, cang)

		return {
			origin = cpos,
			angles = cang,
			fov = fov,
			drawviewer = true
		}
	end)

	hook.Add("PreDrawViewModel", "mw_3p_hide_vm", function(vm, ply)
		if Using3PBase(ply) then return true end
	end)
end