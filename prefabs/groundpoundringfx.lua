local assets =
{
	Asset("ANIM", "anim/bearger_ring_fx.zip"),
}

local function fn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	
    anim:SetBank("bearger_ring_fx")
    anim:SetBuild("bearger_ring_fx")
    anim:PlayAnimation("idle")
    anim:SetFinalOffset(-1)

    anim:SetOrientation( ANIM_ORIENTATION.OnGround )
    anim:SetLayer( LAYER_BACKGROUND )
    anim:SetSortOrder( 3 )

    inst:AddTag("FX")
    inst:AddTag("NOBLOCK")
    
	inst.persists = false
	inst:ListenForEvent("animover", inst.Remove)
	inst:ListenForEvent("entitysleep", inst.Remove)

    return inst
end

return Prefab("common/fx/groundpoundring_fx", fn, assets) 
