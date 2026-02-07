SWEP.SoundStartHandle = nil
SWEP.SoundLoopHandle = nil
SWEP.SoundIsLooping = false

function SWEP:PlayShootSound()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- looping gun
    if self.LoopShootingSound then
        -- if loop already running, restart ONLY the loop
        if self.SoundIsLooping and self.SoundLoopHandle then
            self.SoundLoopHandle:Stop()
            self.SoundLoopHandle:PlayEx(1, 100)
            return
        end

        -- loop not running yet → play start sound once
        self:MW_StartLoopingShootSound()
        return
    end

    -- non-looping gun
    if self.SoundShootPrimary and self.SoundShootPrimary ~= "" then
        self.SoundStartHandle = CreateSound(owner, self.SoundShootPrimary)
        if self.SoundStartHandle then
            self.SoundStartHandle:PlayEx(1, 100)
        end
    end
end

function SWEP:MW_StartLoopingShootSound()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- play start sound ONCE
    if self.SoundShootPrimary and self.SoundShootPrimary ~= "" then
        self.SoundStartHandle = CreateSound(owner, self.SoundShootPrimary)
        if self.SoundStartHandle then
            self.SoundStartHandle:PlayEx(1, 100)
        end
    end

    -- schedule loop
    timer.Create("mw_loopstart_" .. self:EntIndex(), 0.1, 1, function()
        if not IsValid(self) then return end
        if not owner:KeyDown(IN_ATTACK) then return end
        self:MW_BeginShootLoop()
    end)
end

function SWEP:MW_BeginShootLoop()
    if self.SoundIsLooping then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self.SoundLoopHandle = CreateSound(owner, self.SoundShootLoop)
    if self.SoundLoopHandle then
        self.SoundLoopHandle:PlayEx(1, 100)
        self.SoundIsLooping = true
    end
end

function SWEP:MW_StopLoopingSound()
    if self.SoundLoopHandle then
        self.SoundLoopHandle:Stop()
        self.SoundLoopHandle = nil
    end

    if self.SoundStartHandle then
        self.SoundStartHandle:Stop()
        self.SoundStartHandle = nil
    end

    if self.SoundIsLooping then
        self.SoundIsLooping = false

        local owner = self:GetOwner()
        if IsValid(owner) and self.SoundShootEnd and self.SoundShootEnd ~= "" then
            owner:EmitSound(self.SoundShootEnd)
        end
    end
end

function SWEP:Think_SoundSystem()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if not self.LoopShootingSound then return end

    if self.SoundLoopHandle or self.SoundStartHandle then
        if not owner:KeyDown(IN_ATTACK) then
            self:MW_StopLoopingSound()
        end
    end
end
