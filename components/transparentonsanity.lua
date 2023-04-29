local function PushAlpha(self, alpha, most_alpha)
    self.inst.AnimState:SetMultColour(1, 1, 1, alpha)
    if self.inst.SoundEmitter ~= nil then
        self.inst.SoundEmitter:OverrideVolumeMultiplier(alpha / most_alpha)
    end
end

local TransparentOnSanity = Class(function(self, inst)
    self.inst = inst
    self.offset = math.random()
    self.osc_speed = .25 + math.random() * 2
    self.osc_amp = .25 --amplitude
    self.alpha = 0
    self.most_alpha = .4
    self.target_alpha = nil

    PushAlpha(self, 0, .4)
    inst:StartUpdatingComponent(self)
end)

function TransparentOnSanity:OnUpdate(dt)
    self:DoUpdate(dt, false)
end

function TransparentOnSanity:ForceUpdate()
    self:DoUpdate(0, true)
end

function TransparentOnSanity:CalcaulteTargetAlpha()
    local player = GetPlayer()
    if player == nil then
        return 0
    end

    local combat = self.inst.components.combat
    if combat ~= nil and combat.target == player then
        return self.most_alpha
    end

    local pct

    local sanity = player.components.sanity
    if sanity ~= nil then
        pct = 1 - sanity:GetPercent()
    end


    if pct ~= nil then
        return pct * self.most_alpha
            * (1 + self.osc_amp * (math.sin(self.offset * self.osc_speed) - 1)) --variance
    end

    return 0
end

function TransparentOnSanity:DoUpdate(dt, force)
    self.offset = self.offset + dt
    self.target_alpha = self:CalcaulteTargetAlpha()

    if force then
        self.alpha = self.target_alpha
        PushAlpha(self, self.alpha, self.most_alpha)
    elseif self.alpha ~= self.target_alpha then
        self.alpha = self.alpha > self.target_alpha and
            math.max(self.target_alpha, self.alpha - dt) or
            math.min(self.target_alpha, self.alpha + dt)
        PushAlpha(self, self.alpha, self.most_alpha)
    end
end

function TransparentOnSanity:GetDebugString()
    return "alpha = "..self.alpha
end

return TransparentOnSanity
