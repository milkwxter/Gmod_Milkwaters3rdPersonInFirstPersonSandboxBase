-- sh_reload.lua
function SWEP:CanReload()
    if self.Reloading then return false end

    -- clip already full
    if self:Clip1() >= self.Primary.ClipSize then return false end

    local owner = self:GetOwner()
    if not IsValid(owner) then return false end

    -- no reserve ammo
    if owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return false end

    return true
end

function SWEP:Reload()
    if not self:CanReload() then return end
	
	self:SetZoomed(false)
	
	self:SendWeaponAnim(ACT_VM_RELOAD)
	
    self:StartReload()
end

function SWEP:StartReload()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self.Reloading = true
    self.ReloadEnd = CurTime() + self.ReloadTime

    -- play 3p animation
    owner:DoAnimationEvent(self.ReloadGesture)
	
	-- stop looping sound
	self:MW_StopLoopingSound()
end

function SWEP:FinishReload()
    self.Reloading = false

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local ammo = owner:GetAmmoCount(self.Primary.Ammo)
    local needed = self.Primary.ClipSize - self:Clip1()

    local toLoad = math.min(needed, ammo)

    self:SetClip1(self:Clip1() + toLoad)
    owner:SetAmmo(ammo - toLoad, self.Primary.Ammo)
	
	self:SendWeaponAnim(ACT_RELOAD_FINISH)
end