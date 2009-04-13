local addon = nMeter
local window = CreateFrame("Frame", nil, UIParent)
addon.window = window

-- SETTINGS
local s = {
	pos = { "TOPLEFT", 4, -4 },
	width = 280,
	maxlines = 9,

	titleheight = 16,
	titlefont = [[Fonts\ARIALN.TTF]],
	titlefontsize = 13,
	titlefontcolor = {1, .82, 0},

	lineheight = 14,
	linegap = 1,
	linefont = [[Fonts\ARIALN.TTF]],
	linefontsize = 11,
	linetexture = [[Interface\Tooltips\UI-Tooltip-Background]],
	linefontcolor = {1, 1, 1},
}

local noop = function() end
local backAction = noop
local clickFunction = function(self, btn)
	if btn == "LeftButton" then
		self.detailAction(self)
	elseif btn == "RightButton" then
		backAction(self)
	end
end
function window:OnInitialize()
	self.maxlines = s.maxlines
	self:SetWidth(s.width)
	self:SetHeight(3+s.titleheight+s.maxlines*(s.lineheight+s.linegap))

    self:EnableMouse(true)
	self:EnableMouseWheel(true)
    self:SetMovable(true)
    self:RegisterForDrag("LeftButton")

	self:SetBackdrop({
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
        edgeFile = "", tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
	self:SetBackdropColor(0, 0, 0, 1)
	
	self:SetPoint(unpack(s.pos))

	local title = self:CreateTexture(nil, "ARTWORK")
	self.title = title
		title:SetTexture([[Interface\TargetingFrame\UI-StatusBar]])
		title:SetTexCoord(.8, 1, .8, 1)
		title:SetVertexColor(.25, .66, .35, .9)
		title:SetPoint("TOPLEFT", 1, -1)
		title:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -1, -s.titleheight-1)
	local font = self:CreateFontString(nil, "ARTWORK")
	self.titletext = font
		font:SetJustifyH("LEFT")
		font:SetFont(s.titlefont, s.titlefontsize, "OUTLINE")
		font:SetTextColor(s.titlefontcolor[1], s.titlefontcolor[2], s.titlefontcolor[3], 1)
		font:SetPoint("TOPLEFT", 5, -2)

	self.detailAction = noop
	self:SetScript("OnMouseDown", clickFunction)
	self:SetScript("OnMouseWheel", function(self, num)
		addon:Scroll(num)
	end)
end

function window:SetTitle(name, r, g, b)
	self.title:SetVertexColor(r, g, b, .9)
	self.titletext:SetText(name)
end

function window:SetBackAction(f)
	if f then
		backAction = f
	else
		backAction = noop
	end
end

local SetValues = function(f, c, m)
	f:SetMinMaxValues(0, m)
	f:SetValue(c)
end
local SetIcon = function(f, icon)
	f.icon:ClearAllPoints()
	if icon then
		f.icon:SetTexture(icon)
		f.icon:SetPoint("LEFT")
		f.icon:Show()
	else
		f.icon:Hide()
		f.icon:SetPoint("RIGHT", f, "LEFT")
	end
end
local SetLeftText = function(f, ...)
	f.name:SetFormattedText(...)
end
local SetRightText = function(f, ...)
	f.value:SetFormattedText(...)
end
local SetColor = function(f, r, g, b, a)
	f:SetStatusBarColor(r, g, b, a or 1)
end
local SetDetailAction = function(f, func)
	if func then
		f.detailAction = func
	else
		f.detailAction = noop
	end
end
window.SetDetailAction = SetDetailAction

local lines = {}
function window:Clear()
	self:SetBackAction()
	self:SetDetailAction()
	for id,line in pairs(lines) do
		line:SetIcon()
		line:Hide()
	end
end

function window:GetLine(id)
	if lines[id] then return lines[id] end
	
	local f = CreateFrame("StatusBar", nil, self)
	lines[id] = f
		f:EnableMouse(true)
		f.detailAction = noop
		f:SetScript("OnMouseDown", clickFunction)
		f:SetStatusBarTexture(s.linetexture)
		f:SetStatusBarColor(.6, .6, .6, 1)
		f:SetWidth(s.width-4)
		f:SetHeight(s.lineheight)
	if id == 0 then
		f:SetPoint("TOP", self.title, "BOTTOM", 0, -1)
	else
		f:SetPoint("TOP", lines[id-1], "BOTTOM", 0, -s.linegap)
	end
	local icon = f:CreateTexture(nil, "OVERLAY")
	f.icon = icon
		icon:SetWidth(s.lineheight)
		icon:SetHeight(s.lineheight)
		icon:SetPoint("RIGHT", f, "LEFT")
		icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		icon:Hide()
	local value = f:CreateFontString(nil, "ARTWORK")
	f.value = value
		value:SetHeight(s.lineheight)
		value:SetJustifyH("RIGHT")
		value:SetFont(s.linefont, s.linefontsize)
		value:SetTextColor(s.linefontcolor[1], s.linefontcolor[2], s.linefontcolor[3], 1)
		value:SetPoint("RIGHT", -1, 0)
	local name = f:CreateFontString(nil, "ARTWORK")
	f.name = name
		name:SetHeight(s.lineheight)
		name:SetNonSpaceWrap(false)
		name:SetJustifyH("LEFT")
		name:SetFont(s.linefont, s.linefontsize)
		name:SetTextColor(s.linefontcolor[1], s.linefontcolor[2], s.linefontcolor[3], 1)
		name:SetPoint("LEFT", icon, "RIGHT", 1, 0)
		name:SetPoint("RIGHT", value, "LEFT", -1, 0)
	
	f.SetValues = SetValues
	f.SetIcon = SetIcon
	f.SetLeftText = SetLeftText
	f.SetRightText = SetRightText
	f.SetColor = SetColor
	f.SetDetailAction = SetDetailAction

	return f
end

local confirm
function window:GetConfirmWindow()
	if confirm then return confirm end
	
	confirm = CreateFrame("Frame", nil, window)
		confirm:SetWidth(200)
		confirm:SetHeight(50)

	confirm:SetBackdrop({
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
        edgeFile = "", tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
	confirm:SetBackdropColor(0, 0, 0, 1)
	
	confirm:SetPoint("CENTER")

	local title = confirm:CreateTexture(nil, "ARTWORK")
	confirm.title = title
		title:SetTexture([[Interface\TargetingFrame\UI-StatusBar]])
		title:SetTexCoord(.8, 1, .8, 1)
		title:SetVertexColor(.1, .1, .1, .9)
		title:SetPoint("TOPLEFT", 1, -1)
		title:SetPoint("BOTTOMRIGHT", confirm, "TOPRIGHT", -1, -s.titleheight-1)
	local titletext = confirm:CreateFontString(nil, "ARTWORK")
	confirm.titletext = titletext
		titletext:SetJustifyH("LEFT")
		titletext:SetFont(s.titlefont, s.titlefontsize, "OUTLINE")
		titletext:SetTextColor(s.titlefontcolor[1], s.titlefontcolor[2], s.titlefontcolor[3], 1)
		titletext:SetText("nMeter: Confirmation")
		titletext:SetPoint("TOPLEFT", 5, -2)

	return confirm
end
