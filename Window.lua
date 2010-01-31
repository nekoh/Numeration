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
local backdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],--[[Interface\DialogFrame\UI-DialogBox-Background]]---,
	edgeFile = "", tile = true, tileSize = 16, edgeSize = 0,
	insets = { left = 0, right = 0, top = 0, bottom = 0 }
}
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

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	
	self:SetPoint(unpack(s.pos))

	local scroll = self:CreateTexture(nil, "ARTWORK")
	self.scroll = scroll
		scroll:SetTexture([[Interface\Buttons\WHITE8X8]])
		scroll:SetTexCoord(.8, 1, .8, 1)
		scroll:SetVertexColor(0, 0, 0, .8)
		scroll:SetWidth(4)
		scroll:SetHeight(4)
		scroll:Hide()
	
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
		font:SetHeight(s.titleheight)
		font:SetPoint("LEFT", title, "LEFT", 4, 0)
		font:SetPoint("RIGHT", title, "RIGHT", -1, 0)

	self.detailAction = noop
	self:SetScript("OnMouseDown", clickFunction)
	self:SetScript("OnMouseWheel", function(self, num)
		addon:Scroll(num)
	end)
end

function window:SetScrollPosition(curPos, maxPos)
	if maxPos <= s.maxlines then return end
	local total = s.maxlines*(s.lineheight+s.linegap)
	self.scroll:SetHeight(s.maxlines/maxPos*total)
	self.scroll:SetPoint("TOPLEFT", self.title, "BOTTOMRIGHT", 2, -1-(curPos-1)/maxPos*total)
	self.scroll:Show()
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
	f.detailAction = func or noop
end
window.SetDetailAction = SetDetailAction

local lines = {}
function window:Clear()
--	self:SetBackAction()
	self.scroll:Hide()
	self:SetDetailAction()
	for id,line in pairs(lines) do
		line:SetIcon()
		line.spellId = nil
		line:Hide()
	end
end

local onEnter = function(self)
	if not self.spellId then return end
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 4, s.lineheight)
	GameTooltip:SetHyperlink("spell:"..self.spellId)
end
local onLeave = function(self)
	GameTooltip:Hide()
end
function window:GetLine(id)
	if lines[id] then return lines[id] end
	
	local f = CreateFrame("StatusBar", nil, self)
	lines[id] = f
		f:EnableMouse(true)
		f.detailAction = noop
		f:SetScript("OnMouseDown", clickFunction)
		f:SetScript("OnEnter", onEnter)
		f:SetScript("OnLeave", onLeave)
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

local reset
function window:ShowResetWindow()
	if not reset then
		reset = CreateFrame("Frame", nil, window)
		reset:SetBackdrop(backdrop)
		reset:SetBackdropColor(0, 0, 0, 1)
		reset:SetWidth(200)
		reset:SetHeight(45)
		reset:SetPoint("CENTER", UIParent, "CENTER", 0, 200)

		reset.title = reset:CreateTexture(nil, "ARTWORK")
		reset.title:SetTexture([[Interface\TargetingFrame\UI-StatusBar]])
		reset.title:SetTexCoord(.8, 1, .8, 1)
		reset.title:SetVertexColor(.1, .1, .1, .9)
		reset.title:SetPoint("TOPLEFT", 1, -1)
		reset.title:SetPoint("BOTTOMRIGHT", reset, "TOPRIGHT", -1, -s.titleheight-1)
		
		reset.titletext = reset:CreateFontString(nil, "ARTWORK")
		reset.titletext:SetFont(s.titlefont, s.titlefontsize, "OUTLINE")
		reset.titletext:SetTextColor(s.titlefontcolor[1], s.titlefontcolor[2], s.titlefontcolor[3], 1)
		reset.titletext:SetText("nMeter: Reset Data?")
		reset.titletext:SetPoint("TOPLEFT", 5, -2)
		
		reset.yes = CreateFrame("Button", nil, reset)
		reset.yes:SetBackdrop(backdrop)
		reset.yes:SetBackdropColor(0, .2, 0, 1)
		reset.yes:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
		reset.yes:SetNormalFontObject(ChatFontSmall)
		reset.yes:SetText("YES")
		reset.yes:SetWidth(80)
		reset.yes:SetHeight(18)
		reset.yes:SetPoint("BOTTOMLEFT", 10, 5)
		reset.yes:SetScript("OnMouseUp", function() addon:Reset() reset:Hide() end)
		
		reset.no = CreateFrame("Button", nil, reset)
		reset.no:SetBackdrop(backdrop)
		reset.no:SetBackdropColor(.2, 0, 0, 1)
		reset.no:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
		reset.no:SetNormalFontObject(ChatFontSmall)
		reset.no:SetText("NO")
		reset.no:SetWidth(80)
		reset.no:SetHeight(18)
		reset.no:SetPoint("BOTTOMRIGHT", -10, 5)
		reset.no:SetScript("OnMouseUp", function() reset:Hide() end)
	end

	reset:Show()
end
