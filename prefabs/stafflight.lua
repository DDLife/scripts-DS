local assets = 
{
    Asset("ANIM", "anim/star_hot.zip"),
}

local PULSE_SYNC_PERIOD = 30

local function kill_sound(inst)
    inst.SoundEmitter:KillSound("staff_star_loop")
end

local function kill_light(inst)
    inst.AnimState:PlayAnimation("disappear")
    inst:ListenForEvent("animover", kill_sound)
    inst:DoTaskInTime(0.6, inst.Remove)
    inst.persists = false
end

local function ontimer(inst, data)
    if data.name == "extinguish" then
        kill_light(inst)
    end
end

local function pulse_light(inst)
    local timealive = inst:GetTimeAlive()

    if timealive - inst._lastpulsesync > PULSE_SYNC_PERIOD then
        inst._pulsetime = timealive
        inst._lastpulsesync = timealive
    else
        inst._pulsetime = timealive
    end

    inst.Light:Enable(true)

    local s = math.abs(math.sin(PI * (timealive + inst._pulseoffs) * 0.05))
    local rad = Lerp(11, 12, s)
    local intentsity = Lerp(0.8, 0.7, s)
    local falloff = Lerp(0.8, 0.7, s)
    inst.Light:SetFalloff(falloff)
    inst.Light:SetIntensity(intentsity)
    inst.Light:SetRadius(rad)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()

    inst._pulseoffs = 0

    inst:DoPeriodicTask(.1, pulse_light)

    inst.Light:SetColour(223/255, 208/255, 69/255)
    inst.Light:Enable(false)

    inst.AnimState:SetBank("star_hot")
    inst.AnimState:SetBuild("star_hot")
    inst.AnimState:PlayAnimation("appear")
    inst.AnimState:PushAnimation("idle_loop", true)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.no_wet_prefix = true

    inst:AddTag("daylight")

    inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_LP", "staff_star_loop")

    inst._pulsetime = inst:GetTimeAlive()
    inst._lastpulsesync = inst._pulsetime

    inst:AddComponent("cooker")

    inst:AddComponent("propagator")
    inst.components.propagator.heatoutput = 15
    inst.components.propagator.spreading = true
    inst.components.propagator:StartUpdating()

    inst:AddComponent("heater")
    inst.components.heater.heat = 100
   
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL

    inst:AddComponent("inspectable")

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("extinguish", TUNING.YELLOWSTAFF_STAR_DURATION)
    inst:ListenForEvent("timerdone", ontimer)

    inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_create")

    return inst
end

return Prefab("stafflight", fn, assets)