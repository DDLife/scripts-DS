local function makeassetlist(name)
    return {
        Asset("ANIM", "anim/"..name..".zip")
    }
end

local function makefn(name, collide)
    local fn = function()
    	local inst = CreateEntity()
    	inst.entity:AddTransform()
    	inst.entity:AddAnimState()
        if collide then
            MakeObstaclePhysics(inst, 2.75)
        end
        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("idle", true)
        
        return inst
    end

    return fn
end

local function makefn_ruins()
    local inst = makefn("pillar_ruins", true)()

    inst.entity:AddSoundEmitter()

    inst:AddTag("charge_barrier")
    inst:AddTag("quake_on_charge")
    
    local multcolour = 0.5
    local color = multcolour + math.random() * (1.0 - multcolour)
    inst.AnimState:SetMultColour(color, color, color, 1)

    inst:ListenForEvent("shake", function(inst)
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
        inst.SoundEmitter:PlaySound("ancientguardian_rework/environment/pillar_break")
        inst.SoundEmitter:PlaySound("ancientguardian_rework/environment/rocks_falling")
    end)

    return inst
end

local function pillar(name, collide)
    return Prefab( "cave/objects/"..name, makefn(name, collide), makeassetlist(name)) 
end

return  pillar("pillar_algae", true),
        pillar("pillar_cave", true),
        pillar("pillar_stalactite"),
        Prefab("cave/objects/pillar_ruins", makefn_ruins, makeassetlist("pillar_ruins")) 
