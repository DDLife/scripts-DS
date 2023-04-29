local assets =
{
    Asset("ANIM", "anim/rock_ruins.zip"),
    Asset("MINIMAP_IMAGE", "rock"),
}

local prefabs =
{
    "rocks",
    "flint",
    "ruins_cavein_obstacle_rubble_fx",
}

SetSharedLootTable( 'loot1',
{
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'flint',  0.60},
})

local function ShakeCamera(shakeType, duration, speed, maxShake, inst, maxDist)
    GetPlayer().components.playercontroller:ShakeCamera(inst, shakeType, duration, speed, maxShake, maxDist)
end


local function OnWork(inst, worker, workleft)
    if workleft <= 0 then
        local pt = inst:GetPosition()
        
        local fx = SpawnPrefab("ruins_cavein_obstacle_rubble_fx")
        fx.AnimState:SetMultColour(inst.AnimState:GetMultColour())
        fx.Transform:SetPosition(pt:Get())
        fx.setsize(fx,inst.version)

        fx.SoundEmitter:PlaySound("ancientguardian_rework/environment/pillar_break")        

        inst.components.lootdropper:DropLoot(pt)

        if not inst.doNotRemoveOnWorkDone then
            inst:Remove()
        end
    end
end

local function IsHole(x,y,z)
    return GetGroundTypeAtPosition(Vector3(x,y,z)) == GROUND.IMPASSABLE 
end

local function IsPointNearHole(x,y,z)
    local ground = GetWorld()
    local radius = .5


    for i = -radius, radius, 1 do
        if IsHole(x - radius, y, z + i) or IsHole(x + radius, y, z + i) then
            return true
        end
    end
    for i = -(radius - 1), radius - 1, 1 do
        if IsHole(x + i, y, z -radius) or IsHole(x + i, y, z + radius) then
            return true
        end
    end
    return false
end


local _BreakDebris = function(debris)
    local x, y, z = debris.Transform:GetWorldPosition()
    SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(x, 0, z)
    debris:Remove()
end

local function CancelObstacleTask(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
        inst.ischaracterpassthrough = nil
    end
end

local function SetCurrentRadius(inst, radius)
    if inst.currentradius ~= radius then
        inst.currentradius = radius
        inst.Physics:SetCapsule(radius, 2)
    end
end

local CHARACTER_MUST_TAGS = { "character", "locomotor" }
local CHARACTER_CANT_TAGS = { "INLIMBO", "NOCLICK", "flying", "ghost" }
local function OnUpdateObstacleSize(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local mindist = math.huge
    for i, v in ipairs(TheSim:FindEntities(x, y, z, 2, CHARACTER_MUST_TAGS, CHARACTER_CANT_TAGS)) do
        if v.entity:IsVisible() then
            local d = v:GetDistanceSqToPoint(Point(x, y, z))
            d = d > 0 and (v.Physics ~= nil and math.sqrt(d) - v.Physics:GetRadius() or math.sqrt(d)) or 0
            if d < mindist then
                if d <= 0 then
                    mindist = 0
                    break
                end
                mindist = d
            end
        end
    end
    local radius = math.clamp(mindist, 0, inst.maxradius)
    if radius > 0 then
        SetCurrentRadius(inst, radius)
        if inst.ischaracterpassthrough then
            inst.ischaracterpassthrough = nil
            inst.Physics:CollidesWith(COLLISION.CHARACTERS)
            inst.Physics:SetActive(true)
        end
        if radius >= inst.maxradius then
            CancelObstacleTask(inst)
        end
    end
end

local function OnChangeToObstacle(inst)
    inst.Physics:SetMass(0)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    
    inst.ischaracterpassthrough = true
    inst.task = inst:DoPeriodicTask(.5, OnUpdateObstacleSize)
    OnUpdateObstacleSize(inst)
    inst.Physics:Teleport(inst.Transform:GetWorldPosition())
end

local function droponother(inst,other)
    if other:HasTag("smashable") and other.components.health ~= nil then
        other.components.health:Kill()
    elseif other.components.workable ~= nil
        and other.components.workable:CanBeWorked()
        and other.components.workable.action ~= ACTIONS.NET then
        other.components.workable:Destroy(inst)
    elseif other.components.health ~= nil and not other.components.health:IsDead() then
        local dist = inst:GetDistanceSqToInst(other)
        if dist < 3*3 then
            other.components.health:DoDelta(40)
        end
    end
end

local NO_TAGS = {"FX", "NOCLICK", "DECOR","INLIMBO", "stump", "burnt"}

local _endfall = function(debris)
    local x, y, z = debris.Transform:GetWorldPosition()
    debris.Transform:SetPosition(x, 0, z)
    debris.AnimState:PlayAnimation("full"..debris.version)

    debris.SoundEmitter:PlaySound("ancientguardian_rework/environment/pillar_break")

    if debris.updatetask then
        debris.updatetask:Cancel()
        debris.updatetask = nil
    end
    debris.maxradius = 1
    debris.physicstask = debris:DoTaskInTime(.5, OnChangeToObstacle)

    ShakeCamera("VERTICAL", .7, .02, 1.1, debris, 40)

    local x,y,z = debris.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 6, nil, NO_TAGS)
    if #ents > 0 then
        for i, ent in ipairs(ents) do
            if ent ~= debris then
                droponother(debris,ent)
            end
        end
    end
end

local UpdateShadowSize = function(shadow, height)
    local scaleFactor = Lerp(.5*3, 1.5*3, height / 35)
    shadow.Transform:SetScale(scaleFactor, scaleFactor, scaleFactor)
end

local _GroundDetectionUpdate = function(debris)
    local _world = GetWorld()
    local x, y, z = debris.Transform:GetWorldPosition()
    if y <= .3 then
        if not debris:IsOnValidGround() then
            debris:PushEvent("detachchild")
            debris:Remove()
        elseif IsPointNearHole(x, 0, z) then
            _BreakDebris(debris)
        else
            local softbounce = false

            debris.Physics:SetDamping(1)

            debris.shadow:Remove()
            debris.shadow = nil

            debris.updatetask:Cancel()
            debris.updatetask = nil

            _endfall(debris)
        end
    elseif debris:IsInLimbo() then
       debris:Remove()
    else
        if y < 2 then
            debris.Physics:SetMotorVel(0,0,0)
        end
        UpdateShadowSize(debris.shadow, y)
    end
end 

local OnRemoveDebris = function(debris)
    debris.shadow:Remove()
end

local function fall(inst, pt)
    if pt then
        if math.random() < .5 then
            inst.Transform:SetRotation(180)
        end
        inst.AnimState:PlayAnimation("fall"..inst.version)
        inst.shadow = SpawnPrefab("warningshadow")
        inst.shadow:ListenForEvent("onremove", OnRemoveDebris, inst)
        inst.shadow.Transform:SetPosition(pt.x, 0, pt.z)
        UpdateShadowSize(inst.shadow, 35)
        inst.updatetask = inst:DoPeriodicTask(FRAMES, _GroundDetectionUpdate)

        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(GetWorldCollision())

        inst.Physics:SetMass(1)
        inst.Physics:SetDamping(0)
        inst.Physics:Teleport(pt.x, 35, pt.z)
    end
end

local function setversion(inst,version)
    if not version then
        version = math.random(1,4)
    end
    inst.version  = version
end

local function OnSave(inst, data)
    data.version = inst.version
end

local function OnLoad(inst, data)
    if data and data.version then
        inst.version = data.version
        inst.AnimState:PlayAnimation("full"..inst.version)
    end
end

local function baserock_fn(bank, build, anim, icon, tag, multcolour)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()

    MakeCharacterPhysics(inst, 99999, 0.5)
    inst.Transform:SetTwoFaced()
    inst.Transform:SetRotation(math.random(360))

    if icon ~= nil then
        inst.MiniMapEntity:SetIcon(icon)
    end

    setversion(inst)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)

    if type(anim) == "table" then
        for i, v in ipairs(anim) do
            if i == 1 then
                inst.AnimState:PlayAnimation(v..inst.version)
            else
                inst.AnimState:PushAnimation(v..inst.version, false)
            end
        end
    else
        inst.AnimState:PlayAnimation(anim..inst.version)
    end

    inst:AddTag("boulder")
    if tag ~= nil then
        inst:AddTag(tag)
    end

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.ROCKS_MINE)
    inst.components.workable:SetOnWorkCallback(OnWork)

    if multcolour == nil or (0 <= multcolour and multcolour < 1) then
        if multcolour == nil then
            multcolour = 0.5
        end

        local color = multcolour + math.random() * (1.0 - multcolour)
        inst.AnimState:SetMultColour(color, color, color, 1)
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "ROCK"
    MakeSnowCovered(inst)

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    return inst
end

local function fn()
    local inst = baserock_fn("rock_ruins", "rock_ruins", "full", "rock.png", "charge_barrier")

    inst.fall = fall
    
    inst.components.lootdropper:SetChanceLootTable('loot1')

    return inst
end

local function setsize(inst,version)
    if version and (version == 1 or version == 3 ) then
        inst.AnimState:PlayAnimation("break_big")
    else
        inst.AnimState:PlayAnimation("break_small")
    end
end

local function RemoveFx(inst)
    ErodeAway(inst, 1)
end

local function rubblefn(bank, build, anim, icon, tag, multcolour)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()    

    inst:AddTag("FX")

    inst.AnimState:SetBank("rock_ruins")
    inst.AnimState:SetBuild("rock_ruins")
    inst.AnimState:PlayAnimation("break_small")
    inst:ListenForEvent("animover", RemoveFx)
    
    inst.setsize = setsize

    inst.persists = false

    return inst
end

return Prefab("ruins_cavein_obstacle", fn, assets, prefabs),
       Prefab("ruins_cavein_obstacle_rubble_fx", rubblefn, nil, prefabs)