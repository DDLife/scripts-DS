local UsableItem = Class(function(self, inst, activcb)
    self.inst = inst
    self.onusefn = nil
    self.canusefn = nil
end)

function UsableItem:SetOnUseFn(fn)
    self.onusefn = fn
end

function UsableItem:SetCanUseFn(fn)
    self.canusefn = fn
end

function UsableItem:CollectUseActions(doer, target, actions)
    if self.canusefn
        and self.canusefn(self.inst, target, doer)
        and not (
            doer.components.rider ~= nil and doer.components.rider:IsRiding() and
            not (target.components.inventoryitem ~= nil and target.components.inventoryitem:IsGrandOwner(doer))
        )
    then
        table.insert(actions, ACTIONS.GIVE)
    end
end

function UsableItem:Use(doer, target)
    if self.onusefn ~= nil and self.canusefn(self.inst, target, doer) then
        self.onusefn(self.inst, target)
    end
end

return UsableItem
