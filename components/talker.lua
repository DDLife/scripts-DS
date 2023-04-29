local FollowText = require "widgets/followtext"

Line = Class(function(self, message, duration, noanim)
    self.message = message
    self.duration = duration
    self.noanim = noanim
end)


local Talker = Class(function(self, inst)
    self.inst = inst
    self.task = nil
    self.ignoring = false
    self.offset_fn = nil

    self.special_speech = false
end)

function Talker:SetOffsetFn(fn)
    self.offset_fn = fn
end

function Talker:IgnoreAll()
    self.ignoring = true
end

function Talker:StopIgnoringAll()
    self.ignoring = false
end

local function sayfn(self, script)
    if not self.widget then
        self.widget = GetPlayer().HUD:AddChild(FollowText(self.font or TALKINGFONT, self.fontsize or 35))
    end

    self.widget.symbol = self.symbol
    self.widget:SetOffset(self.offset_fn ~= nil and self.offset_fn(self.inst) or self.offset or Vector3(0, -400, 0))
    self.widget:SetTarget(self.inst)

    
    if self.colour then
        self.widget.text:SetColour(self.colour.x, self.colour.y, self.colour.z, 1)
    end

    for k,line in ipairs(script) do
        
        if line.message then
            if self.allcaps then
                self.widget.text:SetString(string.upper(line.message))
            else
                self.widget.text:SetString(line.message)
            end
            self.inst:PushEvent("ontalk", {noanim = line.noanim})
        else
            self.widget:Hide()
        end
        Sleep(line.duration)
    
    end
    self.widget:Kill()    
    self.widget = nil
    self.inst:PushEvent("donetalking")
end

function Talker:OnRemoveEntity()
	self:ShutUp()	
end

function Talker:ShutUp()
    if self.task then
        scheduler:KillTask(self.task)
        
        if self.widget then
            self.widget:Kill()
            self.widget = nil
        end
        self.inst:PushEvent("donetalking")
        self.task = nil
    end
end

function Talker:SetSpecialSpeechFn(fn)
    if fn then self.specialspeechfn = fn end
    self.special_speech = true
end

function Talker:Say(script, time, noanim)
    if self.inst.components.health and  self.inst.components.health:IsDead() then
        return
    end
    
    if self.inst.components.sleeper and  self.inst.components.sleeper:IsAsleep() then
        return
    end
    
    if self.ignoring then
        return
    end

    if self.special_speech then
        if self.specialspeechfn then
            script = self.specialspeechfn(self.inst.prefab)
        else
            script = GetSpecialCharacterString(self.inst.prefab)
        end
    end
    
	if self.ontalk then
		self.ontalk(self.inst, script)
	end
    
    local lines = nil
    if type(script) == "string" then
        lines = {Line(script, time or 2.5, noanim)}
    else
        lines = script
    end

    self:ShutUp()
    if lines then
        self.task = self.inst:StartThread( function() sayfn(self, lines) end)    
    end
end



return Talker
