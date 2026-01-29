-- sh_render.lua
function SWEP:DrawWorldModel()
    local owner = self:GetOwner()

    if not IsValid(owner) then
        self:DrawModel()
        return
    end

    local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand")
    if not boneid then return end

    local matrix = owner:GetBoneMatrix(boneid)
    if not matrix then return end

    local pos, ang = LocalToWorld(
        self.HandOffset_Pos or vector_origin,
        self.HandOffset_Ang or angle_zero,
        matrix:GetTranslation(),
        matrix:GetAngles()
    )

    self:SetRenderOrigin(pos)
    self:SetRenderAngles(ang)

    self:DrawModel()
end