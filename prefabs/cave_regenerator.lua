local PopupDialogScreen = require "screens/popupdialog"

local assets =
{
    Asset("ANIM", "anim/cave_regenerator.zip"),
    Asset("INV_IMAGE", "cave_regenerator"),
    Asset("MINIMAP_IMAGE", "cave_regenerator"),
}

local function DoFX(target)
    target.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")
    
    local x, y, z = target.Transform:GetWorldPosition()
    local scale = 1.2

    local fx = SpawnPrefab("statue_transition_2")
    if fx then
        fx.Transform:SetPosition(x, y, z)
        fx.AnimState:SetScale(scale, scale, scale)
    end

    fx = SpawnPrefab("statue_transition")
    if fx then
        fx.Transform:SetPosition(x, y, z)
        fx.AnimState:SetScale(scale, scale, scale)
    end
end

local function CanUse(inst, target, doer)
    return target.cavenum ~= nil and target.open and not GetWorld():IsCave() and IsGamePurchased()
end

local function OnUse(inst, cave)
    SetPause(true)

    local function cancel()
        TheFrontEnd:PopScreen()
        SetPause(false)
    end

    local function resetcave()
        SetPause(false)
        TheFrontEnd:PopScreen()

        if inst.components.stackable and inst.components.stackable.stacksize > 1 then
            inst = item.components.stackable:Get()
        else
            inst.components.inventoryitem:RemoveFromOwner()
        end
        
        inst:Remove()

        DoFX(cave)

        SaveGameIndex:ResetCave(cave.cavenum)
    end

    TheFrontEnd:PushScreen(PopupDialogScreen(
        STRINGS.UI.RESETCAVE.TITLE, STRINGS.UI.RESETCAVE.BODY,
        {
            {text=STRINGS.UI.RESETCAVE.YES, cb = resetcave},
            {text=STRINGS.UI.RESETCAVE.NO,  cb = cancel}
        }
    ))
end

-- On-air items don't work well with the floatable component.
local function OnHitGround(inst, onwater)
    onwater = onwater == nil and inst:GetIsOnWater() or onwater

    inst.AnimState:PlayAnimation(onwater and "idle_water_loop" or "idle_loop", true)
end

local function fn(Sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local minimap = inst.entity:AddMiniMapEntity()

    minimap:SetIcon("cave_regenerator.png")
    minimap:SetPriority( 7 )

    inst:AddTag("irreplaceable")

    MakeInventoryPhysics(inst)

    anim:SetBank("cave_regenerator")
    anim:SetBuild("cave_regenerator")
    anim:PlayAnimation("idle_loop", true)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.nobounce = true
    inst.components.inventoryitem.nosink = true
    inst.components.inventoryitem.nothrow = true

    inst:AddComponent("usableitem")
    inst.components.usableitem:SetOnUseFn(OnUse)
    inst.components.usableitem:SetCanUseFn(CanUse)

    if GROUND.OCEAN_MEDIUM then
        -- Triggers OnHitGround on spawn.
        inst:DoTaskInTime(0, OnHitGround)

        inst:ListenForEvent("onhitground", OnHitGround)
    end

    return inst
end

return Prefab( "common/inventory/cave_regenerator", fn, assets) 

