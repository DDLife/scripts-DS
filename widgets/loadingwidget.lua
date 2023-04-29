local Widget = require "widgets/widget"
local Text = require "widgets/text"

require "constants"

local LOADER_ATLAS_FMT = "images/bg_loading_%s.%s"

local function GetOneAtlasPerImage_tex(atlas_fmt, item)
    return atlas_fmt:format(item, "xml"), item ..".tex"
end

function GetLoaderAtlasAndTex(item)
    local atlas, tex = GetOneAtlasPerImage_tex(LOADER_ATLAS_FMT, item)
    if softresolvefilepath(atlas) then
        return atlas, tex
    else
        -- No crash.
        return "images/bg_loading_loading_newhorizons.xml", "loading_newhorizons.tex"
    end
end

local bg_loading_images = BG_LOADING_IMAGES.MAIN_GAME

for i, images in ipairs(BG_LOADING_IMAGES.DLCS) do
    if IsDLCInstalled(i) then
        bg_loading_images = ArrayUnion(bg_loading_images, images)
    end
end

local LoadingWidget = Class(Widget, function(self)
    Widget._ctor(self, "LoadingWidget")

    self.forceShowNextFrame = false
    self.is_enabled = false
    self.image_random = GetRandomItem(bg_loading_images)
    self:Hide()

	-- classic
	self.root_classic = self:AddChild(Widget("classic_root"))
	self.root_classic:Hide()

    local atlas, tex = GetLoaderAtlasAndTex(self.image_random)

    local image = self.root_classic:AddChild(Image(atlas, tex))
    image:SetScaleMode(SCALEMODE_FILLSCREEN)
    image:SetVAnchor(ANCHOR_MIDDLE)
    image:SetHAnchor(ANCHOR_MIDDLE)

    self.active_image = image

    local local_loading_widget = self:AddChild(Text(UIFONT, 33))
    local_loading_widget:SetPosition(115, 60)
    local_loading_widget:SetRegionSize(130, 44)
    local_loading_widget:SetHAlign(ANCHOR_LEFT)
    local_loading_widget:SetVAlign(ANCHOR_BOTTOM)
    local_loading_widget:SetString(STRINGS.UI.NOTIFICATION.LOADING)

    self.loading_widget = local_loading_widget
    self.cached_string  = ""
    self.elipse_state = 0
    self.cached_fade_level = 0.0
    self.step_time = GetTime()
end)

function LoadingWidget:ShowNextFrame()
    self.forceShowNextFrame = true
end

function LoadingWidget:SetEnabled(enabled)
    self.is_enabled = enabled
    if enabled then
		self.root_classic:Show()

        self:Show()
	    self:StartUpdating()
    else
        self:Hide()
		self:StopUpdating()
    end
end

function LoadingWidget:KeepAlive(auto_increment)
    if self.is_enabled then
        if TheFrontEnd and auto_increment == false then
            self.cached_fade_level = TheFrontEnd:GetFadeLevel()
        else
            self.cached_fade_level = 1.0
        end

        local fade_sq = self.cached_fade_level * self.cached_fade_level
        self.loading_widget:SetColour(243/255, 244/255, 243/255, fade_sq)

		self.active_image:SetTint(1, 1, 1, fade_sq)

        local time = GetTime()
        local time_delta = time - self.step_time
        local NEXT_STATE = 1.0
        if time_delta > NEXT_STATE or auto_increment then
            if self.elipse_state == 0 then
                self.loading_widget:SetString(STRINGS.UI.NOTIFICATION.LOADING..".")
                self.elipse_state = self.elipse_state + 1
            elseif self.elipse_state == 1 then
                self.loading_widget:SetString(STRINGS.UI.NOTIFICATION.LOADING.."..")
                self.elipse_state = self.elipse_state + 1
            else
                self.loading_widget:SetString(STRINGS.UI.NOTIFICATION.LOADING.."...")
                self.elipse_state = 0
            end
            self.step_time = time
        end

        if 0.01 > self.cached_fade_level then
            self.is_enabled = false
            self:Hide()
			self:StopUpdating()
        end
    end
end

function LoadingWidget:OnUpdate()
    self:KeepAlive(self.forceShowNextFrame)
    self.forceShowNextFrame = false
end

return LoadingWidget
