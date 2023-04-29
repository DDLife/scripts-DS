local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local MorgueScreen = require "screens/morguescreen"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Widget = require "widgets/widget"
require "os"

local SlotDetailsScreen = require "screens/slotdetailsscreen"
local NewGameScreen = require "screens/newgamescreen"
require "fileutil"

local display_rows = 5
local scrollbuttons_scale = 0.8
local scrollbuttons_offset = 260

local LoadGameScreen = Class(Screen, function(self, profile)

	Screen._ctor(self, "LoadGameScreen")
    self.profile = profile
    
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.black:SetTint(0,0,0,.75)	
    
	self.scaleroot = self:AddChild(Widget("scaleroot"))
    self.scaleroot:SetVAnchor(ANCHOR_MIDDLE)
    self.scaleroot:SetHAnchor(ANCHOR_MIDDLE)
    self.scaleroot:SetPosition(0,0,0)
    self.scaleroot:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root = self.scaleroot:AddChild(Widget("root"))
    self.root:SetScale(.9)
    self.bg = self.root:AddChild(Image("images/fepanels.xml", "panel_saveslots.tex"))
	
    local menuitems = 
    {
		{text = STRINGS.UI.LOADGAMESCREEN.CANCEL, cb = function()
			EnableAllDLC()
			TheFrontEnd:PopScreen(self)
		end},
		{text = STRINGS.UI.MORGUESCREEN.MORGUE, cb = function() 
			EnableAllDLC()
			TheFrontEnd:PushScreen( MorgueScreen() ) 
		end},
    }
    self.bmenu = self.root:AddChild(Menu(menuitems, 160, true))
    self.bmenu:SetPosition(-70, -250, 0)

    self.bmenu:SetScale(.8)

	if JapaneseOnPS4() then
        self.title = self.root:AddChild(Text(TITLEFONT, 60 * 0.8))
	else
        self.title = self.root:AddChild(Text(TITLEFONT, 60))
	end
    self.title:SetPosition( 0, 215, 0)
    self.title:SetRegionSize(250,70)
    self.title:SetString(STRINGS.UI.LOADGAMESCREEN.TITLE)
    self.title:SetVAlign(ANCHOR_MIDDLE)

	self.menu = self.root:AddChild(Menu(nil, -80, false))
	self.menu:SetPosition( 0, 143, 0)
	
	self.default_focus = self.menu

	self.option_offset = 0

	self.leftbutton = self.root:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
	self.leftbutton:SetScale(scrollbuttons_scale, scrollbuttons_scale, scrollbuttons_scale)
    self.leftbutton:SetPosition(-scrollbuttons_offset, 0, 0)
	self.leftbutton:SetRotation(180)

	self.leftbutton:SetOnClick(function()
        self:Scroll(-display_rows)
    end)
	
	self.rightbutton = self.root:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
    self.rightbutton:SetPosition(scrollbuttons_offset, 0, 0)
	self.rightbutton:SetScale(scrollbuttons_scale, scrollbuttons_scale, scrollbuttons_scale)
	self.rightbutton:SetRotation(0)
	self.rightbutton:SetOnClick(function()
        self:Scroll(display_rows)
    end)

	self:Scroll(0)
end)

function LoadGameScreen:OnBecomeActive()
	LoadGameScreen._base.OnBecomeActive(self)

	self:Scroll(0)

	self.leftbutton:Show()
	self.rightbutton:Show()

	if self.last_slotnum then
		local idx = self.last_slotnum % display_rows
		local slot_idx = (idx == 0 and display_rows) or idx

		self.menu.items[slot_idx]:SetFocus()
	end
end

function LoadGameScreen:OnBecomeInactive()
	self.leftbutton:Hide()
	self.rightbutton:Hide()
end

function LoadGameScreen:OnControl(control, down)
    if Screen.OnControl(self, control, down) then return true end
    if not down and control == CONTROL_CANCEL then
        EnableAllDLC()
        TheFrontEnd:PopScreen(self)
        return true
    end

	if down then
    	if control == CONTROL_PAGERIGHT then
    		if self.rightbutton.enabled then
    			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
				self:Scroll(display_rows)
    		end
    	elseif control == CONTROL_PAGELEFT then
    		if self.leftbutton.enabled then
    			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
				self:Scroll(-display_rows)
    		end
    	end
	end
end

function LoadGameScreen:RefreshFiles()
	self.menu:Clear()

	local total_page = math.min(self.option_offset + display_rows, NUM_SAVE_SLOTS)

	for k = self.option_offset + 1, total_page do
		local tile = self:MakeSaveTile(k)
		self.menu:AddCustomItem(tile)
	end

	self.menu.items[1]:SetFocusChangeDir(MOVE_UP, self.bmenu)
	self.bmenu:SetFocusChangeDir(MOVE_DOWN, self.menu.items[1])

	self.bmenu:SetFocusChangeDir(MOVE_UP, self.menu.items[#self.menu.items])
	self.menu.items[#self.menu.items]:SetFocusChangeDir(MOVE_DOWN, self.bmenu)

	self.menu.items[1]:SetFocus()
end

function LoadGameScreen:Scroll(dir)
	if (dir > 0 and (self.option_offset + display_rows) < NUM_SAVE_SLOTS) or
		(dir < 0 and self.option_offset + dir >= 0) then
	
		self.option_offset = self.option_offset + dir
	end
	
	self:RefreshFiles()

	if self.option_offset > 0 then
		self.leftbutton:Enable()
	else
		self.leftbutton:Disable()
	end
	
	if self.option_offset + display_rows < NUM_SAVE_SLOTS then
		self.rightbutton:Enable()
	else
		self.rightbutton:Disable()
	end
end

function LoadGameScreen:MakeSaveTile(slotnum)
	
	local widget = Widget("savetile")
	widget.base = widget:AddChild(Widget("base"))
	
	local mode = SaveGameIndex:GetCurrentMode(slotnum)
	local day = SaveGameIndex:GetSlotDay(slotnum)
	local world = SaveGameIndex:GetSlotWorld(slotnum)
	local character = SaveGameIndex:GetSlotCharacter(slotnum)
	local DLC = SaveGameIndex:GetSlotDLC(slotnum)
	local RoG = (DLC ~= nil and DLC.REIGN_OF_GIANTS ~= nil) and DLC.REIGN_OF_GIANTS or false
	local CapyDLC = (DLC ~= nil and DLC.CAPY_DLC ~= nil) and DLC.CAPY_DLC or false
	local PorkDLC = (DLC ~= nil and DLC.PORKLAND_DLC ~= nil) and DLC.PORKLAND_DLC or false
	
    widget.bg = widget.base:AddChild(UIAnim())
    widget.bg:GetAnimState():SetBuild("savetile")
    widget.bg:GetAnimState():SetBank("savetile")
    widget.bg:GetAnimState():PlayAnimation("anim")
	
	widget.portraitbg = widget.base:AddChild(Image("images/saveslot_portraits.xml", "background.tex"))

	widget.portraitbg:SetScale(.60,.60,1)
	if JapaneseOnPS4() then
		widget.portraitbg:SetPosition(-120 + 20, 0, 0)
	else	
		widget.portraitbg:SetPosition(-120 + 40, 0, 0)
	end

	widget.portraitbg:SetClickable(false)	
	
	widget.portrait = widget.base:AddChild(Image())
	widget.portrait:SetClickable(false)	
	if character and mode then	
		local atlas = (table.contains(MODCHARACTERLIST, character) and "images/saveslot_portraits/"..character..".xml") or "images/saveslot_portraits.xml"
		widget.portrait:SetTexture(atlas, character..".tex")
	else
		widget.portraitbg:Hide()
	end

	widget.portrait:SetScale(.60,.60,1)
	if JapaneseOnPS4() then
		widget.portrait:SetPosition(-120 + 20, 0, 0)	
	else
		widget.portrait:SetPosition(-120 + 40, 0, 0)	
	end
	
	if JapaneseOnPS4() then
    	widget.text = widget.base:AddChild(Text(TITLEFONT, 40 * 0.8))	-- KAJ
	else
    	widget.text = widget.base:AddChild(Text(TITLEFONT, 40))
	end

	local function SetShield(shield_img)
		widget.dlcindicator = widget.base:AddChild(Image())
		widget.dlcindicator:SetClickable(false)
		widget.dlcindicator:SetTexture("images/ui.xml", shield_img)
		widget.dlcindicator:SetScale(.5,.5,1)
		widget.dlcindicator:SetPosition(-142, 2, 0)
	end

	if character and mode then
		if PorkDLC then
			SetShield("HAMicon.tex")
		elseif RoG then
			SetShield("DLCicon.tex")
		elseif CapyDLC then
			SetShield("SWicon.tex")
		else
			SetShield("DSicon.tex")
		end

	end

    widget.text = widget.base:AddChild(Text(TITLEFONT, 40))
    widget.text:SetPosition(55,0,0)
    widget.text:SetRegionSize(200 ,70)
    
    if not mode then
		widget.text:SetString(STRINGS.UI.LOADGAMESCREEN.NEWGAME)
		widget.text:SetPosition(0,0,0)
	elseif mode == "adventure" then
		widget.text:SetString(string.format("%s %d-%d",STRINGS.UI.LOADGAMESCREEN.ADVENTURE, world, day))
	elseif mode == "survival" then
		widget.text:SetString(string.format("%s %d-%d",STRINGS.UI.LOADGAMESCREEN.SURVIVAL, world, day))
	elseif mode == "cave" then
		local level = SaveGameIndex:GetCurrentCaveLevel(slotnum)
		widget.text:SetString(string.format("%s %d",STRINGS.UI.LOADGAMESCREEN.CAVE, level))
	elseif mode == "shipwrecked" then
		widget.text:SetString(string.format("%s %d-%d",STRINGS.UI.LOADGAMESCREEN.SHIPWRECKED, world, day))
	elseif mode == "volcano" then
		widget.text:SetString(string.format("%s %d-%d",STRINGS.UI.LOADGAMESCREEN.VOLCANO, world, day))
	elseif mode == "porkland" then
		widget.text:SetString(string.format("%s %d-%d",STRINGS.UI.LOADGAMESCREEN.PORKLAND, world, day))
	else
    	--This should only happen if the user has run a mod that created a new type of game mode.
		widget.text:SetString(STRINGS.UI.LOADGAMESCREEN.MODDED)
	end
	
    widget.text:SetVAlign(ANCHOR_MIDDLE)
    --widget.text:EnableWordWrap(true)

	widget.bg:SetScale(1,.8,1)
    
	widget.OnGainFocus = function(self)
		Widget.OnGainFocus(self)
    	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_mouseover")
    	
    	widget.bg:SetScale(1.05,.87,1)
    	
		widget.bg:GetAnimState():PlayAnimation("over")
	end

    widget.OnLoseFocus = function(self)
    	Widget.OnLoseFocus(self)
    	widget.base:SetPosition(0,0,0)

    	widget.bg:SetScale(1,.8,1)
    	
		widget.bg:GetAnimState():PlayAnimation("anim")
    end
        
    local screen = self
    widget.OnControl = function(self, control, down)
		if control == CONTROL_ACCEPT then
			if down then 
				widget.base:SetPosition(0,-5,0)
			else
				widget.base:SetPosition(0,0,0) 
				screen:OnClickTile(slotnum)
			end
			return true
		end
	end
	
	widget.GetHelpText = function(self)
	    local controller_id = TheInput:GetControllerID()
	    local t = {}
        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HELP.SELECT)	
	    return table.concat(t, "  ")
    end

	return widget
end

function LoadGameScreen:OnClickTile(slotnum)
	self.last_slotnum = slotnum
	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")	
	if not SaveGameIndex:GetCurrentMode(slotnum) then
		TheFrontEnd:PushScreen(NewGameScreen(slotnum))
	else
		local DLC = SaveGameIndex:GetSlotDLC(slotnum)
		local RoGDLC = (DLC ~= nil and DLC.REIGN_OF_GIANTS ~= nil) and DLC.REIGN_OF_GIANTS or false
		local CapyDLC = (DLC ~= nil and DLC.CAPY_DLC ~= nil) and DLC.CAPY_DLC or false
        local PorkDLC = (DLC ~= nil and DLC.PORKLAND_DLC ~= nil) and DLC.PORKLAND_DLC or false

		if RoGDLC then
			EnableDLC(REIGN_OF_GIANTS)
		else
			DisableDLC(REIGN_OF_GIANTS)
		end

		if CapyDLC then
			EnableDLC(CAPY_DLC)
		else
			DisableDLC(CAPY_DLC)
		end

        if PorkDLC then
            EnableDLC(PORKLAND_DLC)
        else
            DisableDLC(PORKLAND_DLC)
        end

		local worlds = 
		{
			porkland = SaveGameIndex:OwnsMode("porkland", slotnum),
			shipwrecked = SaveGameIndex:OwnsMode("shipwrecked", slotnum),
			survival = SaveGameIndex:OwnsMode("survival", slotnum),
		}
		
		TheFrontEnd:PushScreen(SlotDetailsScreen(slotnum, worlds))
		
	end
end

function LoadGameScreen:GetHelpText()
	local t = {}
	local controller_id = TheInput:GetControllerID()

	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

	if self.leftbutton.enabled then 
    	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_PAGELEFT) .. " " .. STRINGS.UI.HELP.SCROLLBACK)
    end

    if self.rightbutton.enabled then
    	table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_PAGERIGHT) .. " " .. STRINGS.UI.HELP.SCROLLFWD)
    end

	return table.concat(t, "  ")
end


return LoadGameScreen