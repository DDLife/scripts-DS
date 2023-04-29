local assets =
{
	Asset("ANIM", "anim/staff.zip"),
}

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
    inst.Transform:SetFourFaced()
    anim:SetBank("staff_fx")
    anim:SetBuild("staff")
    anim:PlayAnimation("staff")

    inst:AddTag("FX")
    inst:AddTag("NOBLOCK")
    
    inst.persists = false
	inst:ListenForEvent("animover", inst.Remove)
	inst:ListenForEvent("entitysleep", inst.Remove)

    return inst
end

return Prefab("common/fx/staffcastfx", fn, assets) 
