-- sh_render.lua
function SWEP:DrawWorldModel()
    if not IsValid(self.WModel) then return end

    local owner = self:GetOwner()

    if IsValid(owner) then
        local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand")
        if boneid then
            local matrix = owner:GetBoneMatrix(boneid)
            if matrix then
                local pos, ang = LocalToWorld(
                    self.HandOffset_Pos or vector_origin,
                    self.HandOffset_Ang or angle_zero,
                    matrix:GetTranslation(),
                    matrix:GetAngles()
                )
				
				-- clientside model
                self.WModel:SetPos(pos)
                self.WModel:SetAngles(ang)
				self.WModel:DrawModel()
				
				-- serverside model
				self:SetRenderOrigin(pos)
				self:SetRenderAngles(ang)
            end
        end
    end
end
