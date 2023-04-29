local assets =
{
	Asset("ANIM", "anim/poop_cloud.zip"),
}

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	
    anim:SetBank("poopcloud")
    anim:SetBuild("poop_cloud")
    anim:PlayAnimation("idle")
    anim:SetFinalOffset(-1)
    inst:AddTag("fx")
    
	inst.persists = false
	inst:ListenForEvent("animover", inst.Remove)
	inst:ListenForEvent("entitysleep", inst.Remove)
    return inst
end

return Prefab("common/fx/poopcloud", fn, assets) 
