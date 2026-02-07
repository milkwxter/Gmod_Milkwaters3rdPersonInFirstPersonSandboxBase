-- cl_viewmodel_bones.lua
-- draws viewmodel bone positions, parent links, and bone names

if not CLIENT then return end

local col_bone = Color(0, 255, 255)
local col_link = Color(255, 255, 0)
local col_text = Color(255, 255, 255)

local show = false

hook.Add("PostDrawViewModel", "vm_bone_debug", function(vm, ply, weapon)
    if not IsValid(vm) then return end
	
	if not show then return end

    local boneCount = vm:GetBoneCount()
    if not boneCount or boneCount <= 0 then return end

    for i = 0, boneCount - 1 do
        local m = vm:GetBoneMatrix(i)
        if not m then continue end

        local pos = m:GetTranslation()
        local ang = m:GetAngles()

        render.SetColorMaterial()

        -- draw bone point
        render.DrawSphere(pos, 0.25, 8, 8, col_bone)

        -- draw parent link
        local parent = vm:GetBoneParent(i)
        if parent and parent >= 0 then
            local pm = vm:GetBoneMatrix(parent)
            if pm then
                render.DrawLine(pos, pm:GetTranslation(), col_link, true)
            end
        end

        -- draw bone name
        local name = vm:GetBoneName(i) or ("bone_" .. i)
        local textPos = pos + ang:Up() * 2.5

        cam.Start3D2D(textPos, Angle(0, EyeAngles().y - 90, 90), 0.05)
            draw.SimpleText(name, "DermaDefault", 0, 0, Color(255,255,255),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
	
	for i = 0, vm:GetBoneCount() - 1 do
        render.SetColorMaterial()

        -- draw bone point
        render.DrawSphere(vm:GetBonePosition( i ), 0.25, 8, 8, col_bone)
	end
end)
