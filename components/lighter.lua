local Lighter = Class(function(self, inst)
    self.inst = inst
    self.onlight = nil
end)

function Lighter:SetOnLightFn(fn)
    self.onlight = fn
end

function Lighter:CanLight(doer, target)
    if doer.components.rider ~= nil and doer.components.rider:IsRiding() then
        if not (target.components.inventoryitem and target.components.inventoryitem:IsGrandOwner(doer)) then
            return false
        end
    end

    if target.components.burnable and not target.components.burnable:IsBurning() and target.components.burnable:IsLightable() then
       return not (target.components.fueled and target.components.fueled:GetPercent() <= 0)
    end

    return false
end

function Lighter:CollectUseActions(doer, target, actions)
    if self:CanLight(doer, target) then
        table.insert(actions, ACTIONS.LIGHT)
    end
end

function Lighter:CollectEquippedActions(doer, target, actions, right)
    if right and self:CanLight(doer, target) then
        table.insert(actions, ACTIONS.LIGHT)
    end
end

function Lighter:Light(target)
    if target.components.burnable then
        local is_empty = target.components.fueled and target.components.fueled:GetPercent() <= 0
        if not is_empty then
            target.components.burnable:Ignite()
            if self.onlight then
                self.onlight(self.inst, target)
            end
        end
    end
end

return Lighter