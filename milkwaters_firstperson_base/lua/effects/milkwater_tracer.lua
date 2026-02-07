EFFECT.Mat = Material("trails/laser")

function EFFECT:Init(data)
    -- engine fallback positions
    local start = data:GetStart()
    local endpos = data:GetOrigin()

    self.StartPos = start
    self.EndPos   = endpos

    -- try to get muzzle attachment if possible
    local ent = data:GetEntity()
    local att = data:GetAttachment()

    if IsValid(ent) and att and att > 0 then
        -- try viewmodel first
        local owner = ent:GetOwner()
        if IsValid(owner) and owner == LocalPlayer() then
            local vm = owner:GetViewModel()
            if IsValid(vm) then
                local vmatt = vm:GetAttachment(att)
                if vmatt then
                    self.StartPos = vmatt.Pos
                end
            end
        end

        -- fallback to worldmodel attachment
        if self.StartPos == start then
            local wmatt = ent:GetAttachment(att)
            if wmatt then
                self.StartPos = wmatt.Pos
            end
        end
    end

    self.LifeTime = 0.5
    self.DieTime  = CurTime() + self.LifeTime
end

function EFFECT:Think()
    return CurTime() < self.DieTime
end

function EFFECT:Render()
    local frac = (self.DieTime - CurTime()) / self.LifeTime
    local width = 3 * frac
    local fade  = 100 * frac

    render.SetMaterial(self.Mat)
    render.DrawBeam(
        self.StartPos,
        self.EndPos,
        width,
        0,
        1,
        Color(255, 255, 255, fade)
    )
end
