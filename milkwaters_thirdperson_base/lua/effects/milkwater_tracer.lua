EFFECT.Mat = Material("trails/laser")

function EFFECT:Init(data)
    local start = data:GetStart()
    local endpos = data:GetOrigin()

    self.StartPos = start
    self.EndPos = endpos

    self.LifeTime = 0.1
    self.DieTime  = CurTime() + self.LifeTime
end

function EFFECT:Think()
    return CurTime() < self.DieTime
end

function EFFECT:Render()
    local frac = (self.DieTime - CurTime()) / self.LifeTime
    local width = 10 * frac
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
