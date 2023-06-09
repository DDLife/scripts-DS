require "util"
require "strings"
local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Menu = require "widgets/menu"
local Grid = require "widgets/grid"
local Text = require "widgets/text"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local Spinner = require "widgets/spinner"
local NumericSpinner = require "widgets/numericspinner"
local Widget = require "widgets/widget"

local PopupDialogScreen = require "screens/popupdialog"
local BigerPopupDialogScreen = require "screens/bigerpopupdialog"

local show_graphics = PLATFORM ~= "NACL"
local text_font = UIFONT--NUMBERFONT

local spinnerFont = { font = BUTTONFONT, size = 30 }

local function GetResolutionString( w, h )
	--return string.format( "%dx%d @ %dHz", w, h, hz )
	return string.format( "%d x %d", w, h )
end

local function SortKey( data )
	local key = data.w * 16777216 + data.h * 65536-- + data.hz
	return key
end

local function ValidResolutionSorter( a, b )
	return SortKey( a.data ) < SortKey( b.data )
end

local function GetDisplays()
	local gOpts = TheFrontEnd:GetGraphicsOptions()
	local num_displays = gOpts:GetNumDisplays()
	local displays = {}
	for i = 0, num_displays - 1 do
		local display_name = gOpts:GetDisplayName( i )
		table.insert( displays, { text = display_name, data = i } )
	end
	
	return displays
end

local function GetRefreshRates( display_id, mode_idx )
	local gOpts = TheFrontEnd:GetGraphicsOptions()
	
	local w, h, hz = gOpts:GetDisplayMode( display_id, mode_idx )
	local num_refresh_rates = gOpts:GetNumRefreshRates( display_id, w, h )
	
	local refresh_rates = {}
	for i = 0, num_refresh_rates - 1 do
		local refresh_rate = gOpts:GetRefreshRate( display_id, w, h, i )
		table.insert( refresh_rates, { text = string.format( "%d", refresh_rate ), data = refresh_rate } )
	end
	
	return refresh_rates
end


local function GetDisplayModes( display_id )
	local gOpts = TheFrontEnd:GetGraphicsOptions()
	local num_modes = gOpts:GetNumDisplayModes( display_id )
	
	local res_data = {}
	for i = 0, num_modes - 1 do
		local w, h, hz = gOpts:GetDisplayMode( display_id, i )
		local res_str = GetResolutionString( w, h )
		res_data[ res_str ] = { w = w, h = h, hz = hz, idx = i }
	end

	local valid_resolutions = {}
	for res_str, data in pairs( res_data ) do
		table.insert( valid_resolutions, { text = res_str, data = data } )
	end

	table.sort( valid_resolutions, ValidResolutionSorter )

	local result = {}
	for k, v in pairs( valid_resolutions ) do
		table.insert( result, { text = v.text, data = v.data } )
	end

	return result
end

local function GetDisplayModeIdx( display_id, w, h, hz )
	local gOpts = TheFrontEnd:GetGraphicsOptions()
	local num_modes = gOpts:GetNumDisplayModes( display_id )
	
	for i = 0, num_modes - 1 do
		local tw, th, thz = gOpts:GetDisplayMode( display_id, i )
		if tw == w and th == h and thz == hz then
			return i
		end
	end
	
	return nil
end

local function GetDisplayModeInfo( display_id, mode_idx )
	local gOpts = TheFrontEnd:GetGraphicsOptions()
	local w, h, hz = gOpts:GetDisplayMode( display_id, mode_idx )

	return w, h, hz
end

local OptionsScreen = Class(Screen, function(self, in_game)
	Screen._ctor(self, "OptionsScreen")
	self.in_game = in_game
	--TheFrontEnd:DoFadeIn(2)

	self.enableDisableOptions = { { text = STRINGS.UI.OPTIONS.DISABLED, data = false }, { text = STRINGS.UI.OPTIONS.ENABLED, data = true } }
	self.enableScreenFlashOptions = { { text = STRINGS.UI.OPTIONS.DEFAULT, data = 1 }, { text = STRINGS.UI.OPTIONS.DIM, data = 2 } , { text = STRINGS.UI.OPTIONS.DIMMEST, data = 3 } }
	self.integratedbackpackOptions = { { text = STRINGS.UI.OPTIONS.INTEGRATEDBACKPACK_DISABLED, data = false }, { text = STRINGS.UI.OPTIONS.INTEGRATEDBACKPACK_ENABLED, data = true } }

	local graphicsOptions = TheFrontEnd:GetGraphicsOptions()
	self.options = {
		fxvolume = TheMixer:GetLevel( "set_sfx" ) * 10,
		musicvolume = TheMixer:GetLevel( "set_music" ) * 10,
		ambientvolume = TheMixer:GetLevel( "set_ambience" ) * 10,
		bloom = graphicsOptions:IsBloomEnabled(),
		smalltextures = graphicsOptions:IsSmallTexturesMode(),
		distortion = graphicsOptions:IsDistortionEnabled(),
		screenshake = Profile:IsScreenShakeEnabled(),
		hudSize = Profile:GetHUDSize(),
		screenflash = Profile:GetScreenFlash(),
		integratedbackpack = Profile:GetIntegratedBackpack(),
		netbookmode = TheSim:IsNetbookMode(),
		vibration = Profile:GetVibrationEnabled(),
		sendstats = Profile:GetAgreementsSetting(),
		dynamic_loading = TheSim:GetSetting("graphics","dynamic_loading_level") or "0",
	}

	if IsDLCInstalled(REIGN_OF_GIANTS) then
		self.options.wathgrithrfont = Profile:IsWathgrithrFontEnabled()
	end

	--[[if PLATFORM == "WIN32_STEAM" and not self.in_game then
		self.options.steamcloud = TheSim:GetSetting("STEAM", "DISABLECLOUD") ~= "true"
	end--]]

	if show_graphics then

		self.options.display = graphicsOptions:GetFullscreenDisplayID()
		self.options.refreshrate = graphicsOptions:GetFullscreenDisplayRefreshRate()
		self.options.fullscreen = graphicsOptions:IsFullScreen()
		self.options.mode_idx = graphicsOptions:GetCurrentDisplayModeID( self.options.display )
	end

	self.working = deepcopy( self.options )
	
	self.bg = self:AddChild(Image("images/ui.xml", "bg_plain.tex"))
	SetBGcolor(self.bg)

    
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)
    
	self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0,0,0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    
	local shield = self.root:AddChild( Image( "images/globalpanels.xml", "panel.tex" ) )
	shield:SetPosition( 0,0,0 )
	shield:SetSize( 1000, 700 )		
	
	

	self.menu = self.root:AddChild(Menu(nil, -80, false))
	if IsDLCEnabled(REIGN_OF_GIANTS) then
		if show_graphics then
			self.menu:SetPosition(260, -230 ,0)  -- -220
		else
			self.menu:SetPosition(260, -245 ,0)
		end
	else
		if show_graphics then
			self.menu:SetPosition(260, -245 ,0)
		else
			self.menu:SetPosition(260, -215 ,0)
		end
		
	end

	self.menu:SetScale(.8)

	self.grid = self.root:AddChild(Grid())

	self.rightbutton = shield:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
    self.rightbutton:SetPosition(440, 0, 0)
    self.rightbutton:SetOnClick( function() 
			self.activePage = self.activePage + 1
			self:ShowPage()
		end)
    self.rightbutton:Hide()
	
	self.leftbutton = shield:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
    self.leftbutton:SetPosition(-440, 0, 0)
    self.leftbutton:SetScale(-1,1,1)
    self.leftbutton:SetOnClick( function() 
			self.activePage = self.activePage - 1
			self:ShowPage()
		end)	
    self.leftbutton:Hide()
	
	self.grids = {}
	self.dlcspinners = {}
	self.activePage = 1

	self.dlcOptionsTitle = self.root:AddChild( Text( TITLEFONT, 50 ) )
	self.dlcOptionsTitle:SetPosition(0,200,0)
	self.dlcOptionsTitle:Hide()
	self:DoInit()

	for i,v in pairs(self.dlcspinners) do
		self.options[v.dlcname..":"..v.name] = Profile:GetDLCSetting(v.dlcname, v.name)
	end
	self.working = deepcopy( self.options )


	self:InitializeSpinners()
	self:ShowPage()

	self:RefreshControls()

	self.default_focus = self.grid
end)


function OptionsScreen:OnControl(control, down)
    if OptionsScreen._base.OnControl(self, control, down) then return true end
    
    if down then
    	if control == CONTROL_PAGERIGHT then
    		if self.rightbutton.shown then
    			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
				self.activePage = self.activePage + 1
				self:ShowPage()
    		end
    	elseif control == CONTROL_PAGELEFT then
    		if self.leftbutton.shown then
    			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
				self.activePage = self.activePage - 1
				self:ShowPage()

    		end
    	end
    else
	    if control == CONTROL_CANCEL then
			if self:IsDirty() then
				self:ConfirmRevert() --revert and go back, or stay
			else
				self:Back() --just go back
			end
			return true
	    elseif control == CONTROL_ACCEPT and TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
	    	if self:IsDirty() then
	    		self:ApplyChanges() --apply changes and go back, or stay
	    	end
	    end
	end
end


function OptionsScreen:ApplyChanges()
	if self:IsDirty() then
		if self:IsGraphicsDirty() then
			self:ConfirmGraphicsChanges()
		else
			self:ConfirmApply()
		end
	end
end


function OptionsScreen:Back()
	TheFrontEnd:PopScreen()					
end

function OptionsScreen:ConfirmRevert()

	TheFrontEnd:PushScreen(
		PopupDialogScreen( STRINGS.UI.OPTIONS.BACKTITLE, STRINGS.UI.OPTIONS.BACKBODY,
		  { 
		  	{ 
		  		text = STRINGS.UI.OPTIONS.YES, 
		  		cb = function()
					self:RevertChanges()
					TheFrontEnd:PopScreen()
					self:Back()
				end
			},
			
			{ 
				text = STRINGS.UI.OPTIONS.NO, 
				cb = function()
					TheFrontEnd:PopScreen()					
				end
			}
		  }
		)
	)		
end

function OptionsScreen:GetHelpText()
	local t = {}
	local controller_id = TheInput:GetControllerID()

	if self.leftbutton.shown then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PAGELEFT) .. " " .. STRINGS.UI.HELP.SCROLLBACK)
	end
	if self.rightbutton.shown then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PAGERIGHT) .. " " .. STRINGS.UI.HELP.SCROLLFWD)
	end

	if self:IsDirty() then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.UI.HELP.APPLY)
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
	else
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
	end
	return table.concat(t, "  ")
end


function OptionsScreen:Accept()
	self:Save(function() self:Close() end )
end

function OptionsScreen:Save(cb)
	self.options = deepcopy( self.working )

	Profile:SetVolume( self.options.ambientvolume, self.options.fxvolume, self.options.musicvolume )
	Profile:SetBloomEnabled( self.options.bloom )
	Profile:SetDistortionEnabled( self.options.distortion )
	Profile:SetScreenShakeEnabled( self.options.screenshake )
	
	if IsDLCInstalled(REIGN_OF_GIANTS) then Profile:SetWathgrithrFontEnabled( self.options.wathgrithrfont ) end
	Profile:SetHUDSize( self.options.hudSize )

	Profile:SetScreenFlash( self.options.screenflash )

	if self.integratedbackpackSpinner:IsEnabled() then
		Profile:SetIntegratedBackpack( self.options.integratedbackpack )
	end

	Profile:SetVibrationEnabled( self.options.vibration )
	Profile:SetAgreementsSetting( self.options.sendstats )
    TheSim:EnableUserDataCollection( self.options.sendstats )

	for i,v in pairs(self.dlcspinners) do
		Profile:SetDLCSetting(v.dlcname,v.name,self.options[v.dlcname..":"..v.name])
	end

	Profile:Save( function() if cb then cb() end end)	
end

function OptionsScreen:RevertChanges()
	self.working = deepcopy( self.options )
	self:Apply()
	self:InitializeSpinners()
	self:UpdateMenu()							
end

function OptionsScreen:IsDirty()
	for k,v in pairs(self.working) do
		if v ~= self.options[k] then
			return true	
		end
	end
	return false
end

function OptionsScreen:IsGraphicsDirty()
	--print("OptionsScreen:IsGraphicsDirty()")
	if self.working.fullscreen ~= self.options.fullscreen then
		--print("...YES")
		return true
	end

	if self.working.fullscreen then
		-- these options are irrelevant in windowed mode
		local dirty = self.working.display ~= self.options.display or
			self.working.mode_idx ~= self.options.mode_idx or
			self.working.refreshrate ~= self.options.refreshrate
		--print("..."..(dirty and "YES" or "NO"))

		return dirty
	end
	--print("...NO")
	return false
end

function OptionsScreen:ChangeGraphicsMode()
	if show_graphics then
		local gOpts = TheFrontEnd:GetGraphicsOptions()
		local w, h, hz = gOpts:GetDisplayMode( self.working.display, self.working.mode_idx )
		local mode_idx = GetDisplayModeIdx( self.working.display, w, h, self.working.refreshrate) or 0
		gOpts:SetDisplayMode( self.working.display, mode_idx, self.working.fullscreen )
	end

end

function OptionsScreen:ConfirmGraphicsChanges(fn)

	--print("OptionsScreen:ConfirmGraphicsChanges", self.applying)

	if not self.applying then
		self:ChangeGraphicsMode()

		TheFrontEnd:PushScreen(
			PopupDialogScreen( STRINGS.UI.OPTIONS.ACCEPTGRAPHICSTITLE, STRINGS.UI.OPTIONS.ACCEPTGRAPHICSBODY,
			  { { text = STRINGS.UI.OPTIONS.ACCEPT, cb =
					function()

						self:Apply()
						self:Save(
							function() 
								self.applying = false
								self:UpdateMenu()
								TheFrontEnd:PopScreen()
							end)
					end
				},
				{ text = STRINGS.UI.OPTIONS.CANCEL, cb =
					function()
						self.applying = false
						self:RevertChanges()
						self:ChangeGraphicsMode()
						TheFrontEnd:PopScreen()					
					end
				}
			  },
			  { timeout = 10, cb =
				function()
					self.applying = false
					self:RevertChanges()
					self:ChangeGraphicsMode()
					TheFrontEnd:PopScreen()
				end
			  }
			)
		)
	end


end

function OptionsScreen:ConfirmApply( )
	
	TheFrontEnd:PushScreen(
		PopupDialogScreen( STRINGS.UI.OPTIONS.ACCEPTTITLE, STRINGS.UI.OPTIONS.ACCEPTBODY,
		  { 
		  	{ 
		  		text = STRINGS.UI.OPTIONS.ACCEPT, 
		  		cb = function()
					self:Apply()
					self:Save(function() TheFrontEnd:PopScreen() self:Back() end)
				end
			},
			
			{ 
				text = STRINGS.UI.OPTIONS.CANCEL, 
				cb = function()
					TheFrontEnd:PopScreen()					
				end
			}
		  }
		)
	)	
end



function OptionsScreen:ApplyVolume()
	TheMixer:SetLevel("set_sfx", self.working.fxvolume / 10 )
	TheMixer:SetLevel("set_music", self.working.musicvolume / 10 )
	TheMixer:SetLevel("set_ambience", self.working.ambientvolume / 10 )
end

function OptionsScreen:Apply( )
	self:ApplyVolume()
	
	TheInputProxy:EnableVibration(self.working.vibration)
	
	local gopts = TheFrontEnd:GetGraphicsOptions()
	gopts:SetBloomEnabled( self.working.bloom )
	gopts:SetDistortionEnabled( self.working.distortion )
	gopts:SetSmallTexturesMode( self.working.smalltextures )
	Profile:SetScreenShakeEnabled( self.working.screenshake )
	-- this data is has changed to the agreements folder.
	--		Profile:SetSendStatsEnabled( self.working.sendstats )	
	Profile:SetAgreementsSetting( self.working.sendstats )
	if IsDLCInstalled(REIGN_OF_GIANTS) then Profile:SetWathgrithrFontEnabled( self.working.wathgrithrfont ) end
	TheSim:SetNetbookMode(self.working.netbookmode)
	TheSim:SetSetting("graphics","dynamic_loading_level",self.working.dynamic_loading or "0")

	if self.integratedbackpackSpinner:IsEnabled() then
		Profile:SetIntegratedBackpack( self.working.integratedbackpack )
	end
end

function OptionsScreen:Close()
	--TheFrontEnd:DoFadeIn(2)
	TheFrontEnd:PopScreen()
end	


local function MakeMenu(offset, menuitems)
	local menu = Widget("OptionsMenu")	
	local pos = Vector3(0,0,0)
	for k,v in ipairs(menuitems) do
		local button = menu:AddChild(ImageButton())
	    button:SetPosition(pos)
	    button:SetText(v.text)
	    button.text:SetColour(0,0,0,1)
	    button:SetOnClick( v.cb )
	    button:SetFont(BUTTONFONT)
	    button:SetTextSize(40)    
	    pos = pos + offset  
	end
	return menu
end

function OptionsScreen:CreateSpinnerGroup( text, spinner )
	local label_width = 200
	spinner:SetTextColour(0,0,0,1)
	local group = Widget( "SpinnerGroup" )
	local label = group:AddChild( Text( BUTTONFONT, 30, text ) )
	label:SetPosition( -label_width/2 + 20, 0, 0 )
	label:SetRegionSize( label_width, 50 )
	label:SetHAlign( ANCHOR_RIGHT )
	
	group:AddChild( spinner )
	spinner:SetPosition( 125, 0, 0 )
	
	--pass focus down to the spinner
	group.focus_forward = spinner
	return group
end


function OptionsScreen:UpdateMenu()
	self.menu:Clear()
	if TheInput:ControllerAttached() then return end
	if self:IsDirty() then
		self.menu.horizontal = true
		self.menu:AddItem(STRINGS.UI.OPTIONS.APPLY, function() self:ApplyChanges() end, Vector3(50, -90, 0))
		self.menu:AddItem(STRINGS.UI.OPTIONS.REVERT, function() self:RevertChanges() end,  Vector3(-50, -90, 0))
	else
		self.menu.horizontal = false
		self.menu:AddItem(STRINGS.UI.OPTIONS.CLOSE, function() self:Accept() end,  Vector3(0, -90, 0))
	end
end

function OptionsScreen:RefreshControls()
	if IsConsole() then
		return
	end

	if TheInput:ControllerAttached() then
		self.integratedbackpackSpinner:Disable()
		self.integratedbackpackSpinner:UpdateText(STRINGS.UI.OPTIONS.INTEGRATEDBACKPACK_ENABLED)
	else
		self.integratedbackpackSpinner:Enable()
		self.integratedbackpackSpinner:SetSelectedIndex(self.integratedbackpackSpinner.selectedIndex)
	end
	
	self:UpdateMenu()
end

function OptionsScreen:DataCollectionPopup()
	TheFrontEnd:PushScreen(
		BigerPopupDialogScreen( STRINGS.UI.OPTIONS.SENDSTATSPOPUP_TITLE , STRINGS.UI.OPTIONS.SENDSTATSPOPUP_BODY,
		  { 
		  	{ 
		  		text = STRINGS.UI.OPTIONS.CLOSE, 
		  		cb = function()			
		  			TheFrontEnd:PopScreen() 													
				end
			},
		  	{ 
		  		text = STRINGS.UI.OPTIONS.PRIVACY_CENTER, 
		  		cb = function()			
		  			VisitURL("https://www.klei.com/privacy-policy")
				end
			},

		  }
		)
	)
end

function OptionsScreen:DoInit()
	self:DoInitPerformancePage()
	self:DoInitHamletPage()
	self:DoInitMainPage()
end


function OptionsScreen:DoInitHamletPage()
	local showHamletOptions = IsDLCInstalled(PORKLAND_DLC) and IsDLCEnabled(PORKLAND_DLC)
	if not showHamletOptions then 
		return
	end

	local hamletGrid = self.root:AddChild(Grid())
	hamletGrid:InitSize(2, 7, 400, -63)
	hamletGrid:SetPosition(-250, 140, 0)

	local dlcname = "hamlet"
	local hamletOptions = {"renderjunglecanopy", "renderjunglevines"}

	for i,v in pairs(hamletOptions) do
		local spinner = Spinner( self.enableDisableOptions )
		spinner.OnChanged =
			function( _, data )
				self.working[dlcname..":"..v] = data
				self:UpdateMenu()
			end
		hamletGrid:AddItem(self:CreateSpinnerGroup(STRINGS.UI.OPTIONS[v:upper()], spinner), 1, i)	
		self.dlcspinners[#self.dlcspinners+1] = {dlcname = dlcname, name = v, spinner = spinner}
	end

	self.grids[#self.grids+1] = {grid = hamletGrid, title = STRINGS.UI.OPTIONS.HAMLET}
end              

function OptionsScreen:DoInitPerformancePage()

	local perfGrid = self.root:AddChild(Grid())
	perfGrid:InitSize(2, 7, 400, -63)
	perfGrid:SetPosition(-250, 140, 0)

	local dlcname = "Performance"
	local hamletOptions = {"renderjunglecanopy", "renderjunglevines"}

	if show_graphics then
		self.smallTexturesSpinner = Spinner( self.enableDisableOptions )
		self.smallTexturesSpinner.OnChanged =
			function( _, data )
				self.working.smalltextures = data
				--this:Apply()
				self:UpdateMenu()
			end
		self.netbookModeSpinner = Spinner( self.enableDisableOptions )
		self.netbookModeSpinner.OnChanged =
			function( _, data )
				self.working.netbookmode = data
				--this:Apply()
				self:UpdateMenu()
			end
		local dynamicLoadingOptions = { { text = STRINGS.UI.OPTIONS.DISABLED, data = "0" }, { text = STRINGS.UI.OPTIONS.MINIMAL, data = "1" }, { text = STRINGS.UI.OPTIONS.MAXIMAL, data = "2" }}

		self.dynamicLoadingSpinner = Spinner( dynamicLoadingOptions )
		self.dynamicLoadingSpinner.OnChanged =
			function( spinner, data )
				--print(v,data)
				if not self.shownDynamicLoadingWarning then
					TheFrontEnd:PushScreen(PopupDialogScreen(STRINGS.UI.OPTIONS.RESTART_TITLE, STRINGS.UI.OPTIONS.RESTART_DYNAMIC_LOADING_BODY, 
					{
						{text=STRINGS.UI.OPTIONS.OK,     cb = function() 
																	self.shownDynamicLoadingWarning = true
																	self.working.dynamic_loading = data
																	TheFrontEnd:PopScreen() 
																	self:UpdateMenu()
																end },
						{text=STRINGS.UI.OPTIONS.CANCEL, cb = function() 
																	spinner:SetSelected(self.working.dynamic_loading or "0")
																	TheFrontEnd:PopScreen() 
																	self:UpdateMenu()	-- not needed but meh
																end}
					}))
				else
					self.working.dynamic_loading = data
					self:UpdateMenu()	-- not needed but meh
				end
			end


		perfGrid:AddItem(self:CreateSpinnerGroup(STRINGS.UI.OPTIONS.SMALLTEXTURES, self.smallTexturesSpinner), 1, 1)
		perfGrid:AddItem(self:CreateSpinnerGroup(STRINGS.UI.OPTIONS.NETBOOKMODE, self.netbookModeSpinner), 1, 2)
		perfGrid:AddItem(self:CreateSpinnerGroup(STRINGS.UI.OPTIONS.DYNAMIC_LOADING, self.dynamicLoadingSpinner), 1, 3)
	end

	self.grids[#self.grids+1] = {grid = perfGrid, title = STRINGS.UI.OPTIONS.PERFORMANCE}
end              

function OptionsScreen:ShowPage()
	if self.activePage == 1 then
		self.dlcOptionsTitle:Hide()
		self.leftbutton:Hide()
		self.grid:Show()
		for i,v in pairs(self.grids) do
			v.grid:Hide()
		end
		if #self.grids == 1 then
			self.rightbutton:Show()
		end
		self.grid:SetFocus()
		self.dlcOptionsTitle:Show()
		self.dlcOptionsTitle:SetString(STRINGS.UI.OPTIONS.GENERAL)

	else
		self.dlcOptionsTitle:Show()
		self.grid:Hide()
		self.leftbutton:Show()
		if #self.grids > (self.activePage-1) then
			self.rightbutton:Show()
		else
			self.rightbutton:Hide()
		end
		for i,v in pairs(self.grids) do
			if i == self.activePage - 1 then
				v.grid:Show()
				self.dlcOptionsTitle:SetString(v.title)
				v.grid:SetFocus()
			else
				v.grid:Hide()
			end
		end
	end
end

function OptionsScreen:DoInitMainPage()

	if show_graphics then
		self.grid:InitSize(2, 8, 400, -58) -- -63
	else
		self.grid:InitSize(2, 5, 400, -78) -- -83
	end

	if IsDLCEnabled(REIGN_OF_GIANTS) then
		if show_graphics then
			self.grid:SetPosition(-250, 150, 0) --140
		else
			self.grid:SetPosition(-250, 190, 0)
		end
	else
		if show_graphics then
			self.grid:SetPosition(-250, 150, 0)
		else
			self.grid:SetPosition(-250, 165, 0)
		end
	end

	if show_graphics then
		if IsDLCEnabled(REIGN_OF_GIANTS) then
			self.grid:SetScale(1,.9)
		else
			self.grid:SetScale(1,.95)
		end
	end

	self:UpdateMenu()
	--self.menu:SetScale(.8,.8,.8)

	local this = self
	
	if show_graphics then
		local gOpts = TheFrontEnd:GetGraphicsOptions()
	
		self.fullscreenSpinner = Spinner( self.enableDisableOptions )
		
		self.fullscreenSpinner.OnChanged =
			function( _, data )
				this.working.fullscreen = data
				this:UpdateResolutionsSpinner()
				self:UpdateMenu()				
			end
		
		if gOpts:IsFullScreenEnabled() then
			self.fullscreenSpinner:Enable()
		else
			self.fullscreenSpinner:Disable()
		end

		local valid_displays = GetDisplays()
		self.displaySpinner = Spinner( valid_displays )
		self.displaySpinner.OnChanged =
			function( _, data )
				this.working.display = data
				this:UpdateResolutionsSpinner()
				this:UpdateRefreshRatesSpinner()
				self:UpdateMenu()
			end
		
		local refresh_rates = GetRefreshRates( self.working.display, self.working.mode_idx )
		self.refreshRateSpinner = Spinner( refresh_rates) 
		self.refreshRateSpinner.OnChanged =
			function( _, data )
				this.working.refreshrate = data
				self:UpdateMenu()
			end

		local modes = GetDisplayModes( self.working.display )
		self.resolutionSpinner = Spinner( modes )
		self.resolutionSpinner.OnChanged =
			function( _, data )
				this.working.mode_idx = data.idx
				this:UpdateRefreshRatesSpinner()
				self:UpdateMenu()
			end							
	end
	
	self.bloomSpinner = Spinner( self.enableDisableOptions )
	self.bloomSpinner.OnChanged =
		function( _, data )
			this.working.bloom = data
			--this:Apply()
			self:UpdateMenu()
		end
		
	self.distortionSpinner = Spinner( self.enableDisableOptions )
	self.distortionSpinner.OnChanged =
		function( _, data )
			this.working.distortion = data
			--this:Apply()
			self:UpdateMenu()
		end

	self.screenshakeSpinner = Spinner( self.enableDisableOptions )
	self.screenshakeSpinner.OnChanged =
		function( _, data )
			this.working.screenshake = data
			--this:Apply()
			self:UpdateMenu()
		end

	self.fxVolume = NumericSpinner( 0, 10 )
	self.fxVolume.OnChanged =
		function( _, data )
			this.working.fxvolume = data
			this:ApplyVolume()
			self:UpdateMenu()
		end

	self.musicVolume = NumericSpinner( 0, 10 )
	self.musicVolume.OnChanged =
		function( _, data )
			this.working.musicvolume = data
			this:ApplyVolume()
			self:UpdateMenu()
		end

	self.ambientVolume = NumericSpinner( 0, 10 )
	self.ambientVolume.OnChanged =
		function( _, data )
			this.working.ambientvolume = data
			this:ApplyVolume()
			self:UpdateMenu()
		end
		
	self.hudSize = NumericSpinner( 0, 10 )
	self.hudSize.OnChanged =
		function( _, data )
			this.working.hudSize = data
			--this:Apply()
			self:UpdateMenu()
		end

	self.screenFlashSpinner = Spinner( self.enableScreenFlashOptions ) 
	self.screenFlashSpinner.OnChanged =
		function( _, data )
			this.working.screenflash = data
			--this:Apply()
			self:UpdateMenu()
		end

	self.integratedbackpackSpinner = Spinner( self.integratedbackpackOptions ) 
	self.integratedbackpackSpinner.OnChanged =
		function( _, data )
			this.working.integratedbackpack = data
			--this:Apply()
			self:UpdateMenu()
		end

	self.vibrationSpinner = Spinner( self.enableDisableOptions )
	self.vibrationSpinner.OnChanged =
		function( _, data )
			this.working.vibration = data
			--this:Apply()
			self:UpdateMenu()
		end

	self.sendstatsSpinner = Spinner( self.enableDisableOptions )
	self.sendstatsSpinner.OnChanged =
		function( _, data )
			this.working.sendstats = data
			if data == false then
				self:DataCollectionPopup()
			end
			--this:Apply()
			self:UpdateMenu()
		end


	if IsDLCInstalled(REIGN_OF_GIANTS) then
		self.wathgrithrfontSpinner = Spinner( self.enableDisableOptions )
		self.wathgrithrfontSpinner.OnChanged =
			function( _, data )
				this.working.wathgrithrfont = data
				--this:Apply()
				self:UpdateMenu()
			end
	end
		
	local left_spinners = {}
	local right_spinners = {}
	
	if show_graphics then
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.BLOOM, self.bloomSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.DISTORTION, self.distortionSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.SCREENSHAKE, self.screenshakeSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.FULLSCREEN, self.fullscreenSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.DISPLAY, self.displaySpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.RESOLUTION, self.resolutionSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.REFRESHRATE, self.refreshRateSpinner } )
		
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.FX, self.fxVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.MUSIC, self.musicVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.AMBIENT, self.ambientVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.HUDSIZE, self.hudSize} )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.SCREEN_FLASH_INTENSITY, self.screenFlashSpinner} )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.VIBRATION, self.vibrationSpinner} )
		table.insert( right_spinners,  { STRINGS.UI.OPTIONS.BACKPACKMODE, self.integratedbackpackSpinner} )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.SENDSTATS, self.sendstatsSpinner} )
		if IsDLCInstalled(REIGN_OF_GIANTS) then
			table.insert( left_spinners, { STRINGS.UI.OPTIONS.WATHGRITHRFONT, self.wathgrithrfontSpinner} )
		end

	else
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.BLOOM, self.bloomSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.DISTORTION, self.distortionSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.SCREENSHAKE, self.screenshakeSpinner } )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.HUDSIZE, self.hudSize} )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.SCREEN_FLASH_INTENSITY, self.screenFlashSpinner} )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.VIBRATION, self.vibrationSpinner} )
		table.insert( left_spinners, { STRINGS.UI.OPTIONS.BACKPACKMODE, self.integratedbackpackSpinner} )

		table.insert( right_spinners, { STRINGS.UI.OPTIONS.FX, self.fxVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.MUSIC, self.musicVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.AMBIENT, self.ambientVolume } )
		table.insert( right_spinners, { STRINGS.UI.OPTIONS.SENDSTATS, self.sendstatsSpinner} )
		if IsDLCInstalled(REIGN_OF_GIANTS) then
			table.insert( left_spinners, { STRINGS.UI.OPTIONS.WATHGRITHRFONT, self.wathgrithrfontSpinner} )
		end
	end

	for k,v in ipairs(left_spinners) do
		self.grid:AddItem(self:CreateSpinnerGroup(v[1], v[2]), 1, k)	
	end

	for k,v in ipairs(right_spinners) do
		self.grid:AddItem(self:CreateSpinnerGroup(v[1], v[2]), 2, k)	
	end

	if #self.grids > 0 then
		self.rightbutton:Show()
	end
	self.leftbutton:Hide()

end

local function EnabledOptionsIndex( enabled )
	if enabled then
		return 2
	else
		return 1
	end
end

function OptionsScreen:InitializeSpinners()
	-- we want to show this popup again if the player reverts the setting...I think?
	self.shownDynamicLoadingWarning = nil

	if show_graphics then
		self.fullscreenSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.fullscreen ) )
		self:UpdateDisplaySpinner()
		self:UpdateResolutionsSpinner()
		self:UpdateRefreshRatesSpinner()
		self.smallTexturesSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.smalltextures ) )
		self.netbookModeSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.netbookmode ) )
		self.dynamicLoadingSpinner:SetSelected(self.working.dynamic_loading)
	end

	--[[if PLATFORM == "WIN32_STEAM" and not self.in_game then
		self.steamcloudSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.steamcloud ) )
	end
	--]]
	
	self.bloomSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.bloom ) )
	self.distortionSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.distortion ) )
	self.screenshakeSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.screenshake ) )

	local spinners = { fxvolume = self.fxVolume, musicvolume = self.musicVolume, ambientvolume = self.ambientVolume }
	for key, spinner in pairs( spinners ) do
		local volume = self.working[ key ] or 7
		spinner:SetSelectedIndex( math.floor( volume + 0.5 ) )
	end
	
	self.hudSize:SetSelectedIndex( self.working.hudSize or 5)

	self.screenFlashSpinner:SetSelectedIndex( self.working.screenflash or 1)
	self.integratedbackpackSpinner:SetSelectedIndex(EnabledOptionsIndex(self.working.integratedbackpack))
	self.vibrationSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.vibration ) )
	self.sendstatsSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.sendstats ) )
	if IsDLCInstalled(REIGN_OF_GIANTS) then self.wathgrithrfontSpinner:SetSelectedIndex( EnabledOptionsIndex( self.working.wathgrithrfont ) ) end

	for i,v in pairs(self.dlcspinners) do
		--self.dlcspinners[#self.dlcspinners+1] = {name = v, spinner = spinner}
		local value = self.working[v.dlcname..":"..v.name]
		v.spinner:SetSelectedIndex( EnabledOptionsIndex( value ) )
	end
end

function OptionsScreen:UpdateDisplaySpinner()
	if show_graphics then
		local graphicsOptions = TheFrontEnd:GetGraphicsOptions()
		local display_id = graphicsOptions:GetFullscreenDisplayID() + 1
		self.displaySpinner:SetSelectedIndex( display_id )
	end
end

function OptionsScreen:UpdateRefreshRatesSpinner()
	if show_graphics then
		local current_refresh_rate = self.working.refreshrate
		
		local refresh_rates = GetRefreshRates( self.working.display, self.working.mode_idx )
		self.refreshRateSpinner:SetOptions( refresh_rates )
		self.refreshRateSpinner:SetSelectedIndex( 1 )
		
		for idx, refresh_rate_data in ipairs( refresh_rates ) do
			if refresh_rate_data.data == current_refresh_rate then
				self.refreshRateSpinner:SetSelectedIndex( idx )
				break
			end
		end
		
		self.working.refreshrate = self.refreshRateSpinner:GetSelected().data		
	end
end

function OptionsScreen:UpdateResolutionsSpinner()
	if show_graphics then
		local resolutions = GetDisplayModes( self.working.display )
		self.resolutionSpinner:SetOptions( resolutions )
	
		if self.fullscreenSpinner:GetSelected().data then
			self.displaySpinner:Enable()
			self.refreshRateSpinner:Enable()
			self.resolutionSpinner:Enable()

			local spinner_idx = 1
			if self.working.mode_idx then
				local gOpts = TheFrontEnd:GetGraphicsOptions()
				local mode_idx = gOpts:GetCurrentDisplayModeID( self.options.display )
				local w, h, hz = GetDisplayModeInfo( self.working.display, mode_idx )
				
				for idx, option in pairs( self.resolutionSpinner.options ) do
					if option.data.w == w and option.data.h == h then
						spinner_idx = idx
						break
					end
				end
			end
			self.resolutionSpinner:SetSelectedIndex( spinner_idx )
		else
			self.displaySpinner:Disable()
			self.refreshRateSpinner:Disable()
			self.resolutionSpinner:Disable()
		end
	end
end

return OptionsScreen