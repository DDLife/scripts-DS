require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/follow"
require "behaviours/doaction"
require "behaviours/minperiod"
require "behaviours/panic"
require "behaviours/runaway"

local SEE_DIST = 30
local TOOCLOSE = 6

local function CanSteal(item)
    return item.components.inventoryitem ~= nil
        and item.components.inventoryitem.canbepickedup
        and item:IsOnValidGround()
        and not item.components.container
        and not GetPlayer():IsNear(item, TOOCLOSE)
end

local STEAL_CANT_TAGS = {"FX", "INLIMBO", "catchable", "fire", "irreplaceable", "prey", "bird"}

local function StealAction(inst)
    if not inst.components.inventory:IsFull() then
        local target = FindEntity(inst, SEE_DIST,
            CanSteal,
            nil,
            STEAL_CANT_TAGS)
        return target ~= nil
            and BufferedAction(inst, target, ACTIONS.PICKUP)
            or nil
    end
end

local function EmptyChest(inst)
    local notags = {"FX", "NOCLICK", "DECOR","INLIMBO"}
    if not inst.components.inventory:IsFull() then
        local player = GetPlayer()
        local target = FindEntity(inst, SEE_DIST, function(item) 
            if item.prefab == "treasurechest" and 
                item.components.container and
                not item.components.container:IsEmpty() then
                    return player and player:GetDistanceSqToInst(item) > TOOCLOSE*TOOCLOSE
                end
            end, nil, notags)
        if target then
            return BufferedAction(inst, target, ACTIONS.HAMMER)
        end
    end
end

local MIN_FOLLOW = 10
local MAX_FOLLOW = 20
local MED_FOLLOW = 15

local MIN_RUNAWAY = 8
local MAX_RUNAWAY = MED_FOLLOW

local KrampusBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.greed = 2 + math.random(4)
end)

function KrampusBrain:OnStart()
    local stealnode = PriorityNode(
    {
        DoAction(self.inst, function() return StealAction(self.inst) end, "steal", true ),        
        DoAction(self.inst, function() return EmptyChest(self.inst) end, "emptychest", true )
    }, 2)

    local root = PriorityNode(
    {
        WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        ChaseAndAttack(self.inst, 100),
                
        IfNode( function() return self.inst.components.inventory:NumItems() >= self.greed and not self.inst.sg:HasStateTag("busy") end, "donestealing",
            ActionNode(function() self.inst.sg:GoToState("exit") return SUCCESS end, "leave" )),
        MinPeriod(self.inst, 10, stealnode),
        RunAway(self.inst, "player", MIN_RUNAWAY, MAX_RUNAWAY),
        Follow(self.inst, function() return GetPlayer() end, MIN_FOLLOW, MED_FOLLOW, MAX_FOLLOW),
        Wander(self.inst, self.inst:GetPosition(), 10) -- Wander near his spawn location.
    }, 2)
    
    self.bt = BT(self.inst, root)
   
end

return KrampusBrain
