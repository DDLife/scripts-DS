local Repairable = Class(function(self, inst)
    self.inst = inst
    self.repairmaterial = nil
    self.announcecanfix = true
end)

function Repairable:NeedsRepairs()
    if self.inst.components.health then
        return self.inst.components.health:GetPercent() < 1
    elseif self.inst.components.workable and self.inst.components.workable.workleft then
        return self.inst.components.workable.workleft < self.inst.components.workable.maxwork
    elseif self.inst.components.perishable then
        return self.inst.components.perishable:GetPercent() < 1
    elseif self.inst.components.finiteuses then
        return self.inst.components.finiteuses:GetPercent() < 1
    end
    
    return false
end

function Repairable:Repair(doer, repair_item)
    if repair_item.components.repairer == nil or self.repairmaterial ~= repair_item.components.repairer.repairmaterial then
        -- Wrong material.
        return false
    end

    if self.inst.components.health ~= nil then
        if self.inst.components.health:GetPercent() >= 1 then
            return false
        end

        self.inst.components.health:DoDelta(repair_item.components.repairer.healthrepairvalue)

    elseif self.inst.components.workable ~= nil and self.inst.components.workable.workleft ~= nil then
        if self.inst.components.workable.workleft >= self.inst.components.workable.maxwork then
            return false
        end

        self.inst.components.workable:SetWorkLeft(self.inst.components.workable.workleft + repair_item.components.repairer.workrepairvalue)

    elseif self.inst.components.perishable ~= nil and self.inst.components.perishable.perishremainingtime ~= nil then
        if self.inst.components.perishable.perishremainingtime >= self.inst.components.perishable.perishtime then
            return false
        end

        self.inst.components.perishable:SetPercent(self.inst.components.perishable:GetPercent() + repair_item.components.repairer.perishrepairvalue)

    elseif self.inst.components.finiteuses ~= nil then
        if self.inst.components.finiteuses:GetPercent() >= 1 then
            return false
        end

        self.inst.components.finiteuses:Repair(repair_item.components.repairer.finiteusesrepairvalue)

    else
        -- Not repairable.
        return false
    end

    if repair_item.components.stackable then
        repair_item.components.stackable:Get():Remove()
    elseif repair_item.components.finiteuses then
        repair_item.components.finiteuses:Use(1)
    else
        repair_item:Remove()
    end

    if self.onrepaired then
        self.onrepaired(self.inst, doer, repair_item)
    end

    return true
end

return Repairable
