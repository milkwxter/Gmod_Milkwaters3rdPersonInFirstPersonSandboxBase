-- sh_render.lua
function SWEP:CreateWorldModel()
    if IsValid(self.WM) then self.WM:Remove() end

    local mdl = self.GetCurrentWorldModel and self:GetCurrentWorldModel() or self.WorldModel
    if not mdl then return end

    self.WM = ClientsideModel(mdl, RENDERGROUP_OPAQUE)
    if not IsValid(self.WM) then return end

    self.WM:SetNoDraw(true)
end

function SWEP:DrawWorldModel()
    local owner = self:GetOwner()

    -- dropped on ground
    if not IsValid(owner) then
        self:DrawModel()
        return
    end

    -- ensure clientside worldmodel exists
    if not IsValid(self.WM) then
        self.WM = ClientsideModel(self.WorldModel, RENDERGROUP_OPAQUE)
        self.WM:SetNoDraw(true)
    end

    -- get hand bone
    local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
    if not bone then
        -- fallback
        self:DrawModel()
        return
    end

    -- get bone transform
    local pos, ang = owner:GetBonePosition(bone)
    if not pos or not ang then
        self:DrawModel()
        return
    end
	
    pos = pos + ang:Forward() * 2 + ang:Right() * 1 + ang:Up() * -1
    ang:RotateAroundAxis(ang:Right(), 0)
    ang:RotateAroundAxis(ang:Up(), 0)
    ang:RotateAroundAxis(ang:Forward(), 180)

    -- apply transform
    self.WM:SetRenderOrigin(pos)
    self.WM:SetRenderAngles(ang)

    -- draw it
    self.WM:DrawModel()
end

