function FindEntityToDraw(target, tool)
    if target ~= nil then
        local x, y, z = target.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, y, z, 1.5, {"isinventoryitem" }, {"INLIMBO", "NOFORAGE"})) do
            if v ~= target and v ~= tool and v.entity:IsVisible() then
                return v
            end
        end
    end
end

local DrawingTool = Class(function(self, inst)
    self.inst = inst

    self.ondrawfn = nil
end)

function DrawingTool:SetOnDrawFn(fn)
    self.ondrawfn = fn
end

function DrawingTool:GetImageToDraw(target)
    local ent = FindEntityToDraw(target, self.inst)
    return ent ~= nil and (
            ent.components.inventoryitem:GetImage():gsub("%.tex", "")
        ) or nil,
        ent
end

function DrawingTool:Draw(target, image, src)
    if target ~= nil and target.components.drawable ~= nil then
        target.components.drawable:OnDrawn(image, src)
        if self.ondrawfn ~= nil then
            self.ondrawfn(self.inst, target, image, src)
        end
    end
end

function DrawingTool:CollectUseActions(doer, target, actions)
    if target:HasTag("drawable") then
        table.insert(actions, ACTIONS.DRAW)
    end
end

return DrawingTool
