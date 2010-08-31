local addon = select(2, ...)
local window = CreateFrame("Frame", "NumerationFrame", UIParent)
addon.window = window

local lines = {}

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

	self:SetClampedToScreen(true)
	self:EnableMouse(true)
	self:EnableMouseWheel(true)
	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", function() if IsAltKeyDown() then self:StartMoving() end end)
	self:SetScript("OnDragStop", function()
		self:StopMovingOrSizing()
		
		-- positioning code taken from recount
		local xOfs, yOfs = self:GetCenter()
		local s = self:GetEffectiveScale()
		local uis = UIParent:GetScale()
		xOfs = xOfs*s - GetScreenWidth()*uis/2
		yOfs = yOfs*s - GetScreenHeight()*uis/2
		
		addon:SetOption("x", xOfs/uis)
		addon:SetOption("y", yOfs/uis)
	end)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	
	local x, y = addon:GetOption("x"), addon:GetOption("y")
	if not x or not y then
		self:SetPoint(unpack(s.pos))
	else
		-- positioning code taken from recount
		local s = self:GetEffectiveScale()
		local uis = UIParent:GetScale()
		self:SetPoint("CENTER", UIParent, "CENTER", x*uis/s, y*uis/s)
	end

	local dropdown = CreateFrame("Frame", "NumerationMenuFrame", nil, "UIDropDownMenuTemplate")
	local optionFunction = function(f, id, _, checked)
		addon:SetOption(id, checked)
	end
	local reportFunction = function(f, chatType, channel)
		addon:Report(9, chatType, channel)
		CloseDropDownMenus()
	end
	local menuTable = {
		{ text = "Numeration", isTitle = true, notCheckable = true, notClickable = true },
		{ text = "Report", notCheckable = true, hasArrow = true,
			menuList = {
				{ text = 'Say', arg1 = "SAY", func = reportFunction, notCheckable = 1 },
				{ text = 'Raid', arg1 = "RAID", func = reportFunction, notCheckable = 1 },
				{ text = 'Party', arg1 = "PARTY", func = reportFunction, notCheckable = 1 },
				{ text = 'Guild', arg1 = "GUILD", func = reportFunction, notCheckable = 1 },
				{ text = 'Whisper', arg1 = "WHISPER", arg2 = "target", func = reportFunction, notCheckable = 1 },
				{ text = 'Channel  ', notCheckable = 1, keepShownOnClick = true, hasArrow = true, menuList = {} }
			},
		},
		{ text = "Options", notCheckable = true, hasArrow = true,
			menuList = {
				{ text = "Merge Pets w/ Owners", arg1 = "petsmerged", func = optionFunction, checked = function() return addon:GetOption("petsmerged") end, keepShownOnClick = true },
				{ text = "Keep Only Boss Segments", arg1 = "keeponlybosses", func = optionFunction, checked = function() return addon:GetOption("keeponlybosses") end, keepShownOnClick = true },
				{ text = "Record Deathlog", arg1 = "deathlog", func = optionFunction, checked = function() return addon:GetOption("deathlog") end, keepShownOnClick = true },
				{ text = "Record Only In Instances", arg1 = "onlyinstance", func = optionFunction, checked = function() return addon:GetOption("onlyinstance") end, keepShownOnClick = true },
			},
		},
		{ text = "", notClickable = true },
		{ text = "Reset", func = function() self:ShowResetWindow() end, notCheckable = true },
	}

	local scroll = self:CreateTexture(nil, "ARTWORK")
	self.scroll = scroll
		scroll:SetTexture([[Interface\Buttons\WHITE8X8]])
		scroll:SetTexCoord(.8, 1, .8, 1)
		scroll:SetVertexColor(0, 0, 0, .8)
		scroll:SetWidth(4)
		scroll:SetHeight(4)
		scroll:Hide()
	
	local reset = CreateFrame("Button", nil, self)
	self.reset = reset
		reset:SetBackdrop(backdrop)
		reset:SetBackdropColor(0, 0, 0, .8)
		reset:SetNormalFontObject(ChatFontSmall)
		reset:SetText(">")
		reset:SetWidth(s.titleheight)
		reset:SetHeight(s.titleheight)
		reset:SetPoint("TOPRIGHT", -1, -1)
		reset:SetScript("OnMouseUp", function()
			menuTable[2].menuList[6].menuList = table.wipe(menuTable[2].menuList[6].menuList)
			for i = 1, GetNumDisplayChannels() do
				local name, _, _, channelNumber, _, active, category = GetChannelDisplayInfo(i)
				if category == "CHANNEL_CATEGORY_CUSTOM" then
					tinsert(menuTable[2].menuList[6].menuList, { text = name, arg1 = "CHANNEL", arg2 = channelNumber, func = reportFunction, notCheckable = 1 })
				end
			end
			EasyMenu(menuTable, dropdown, "cursor", 0 , 0, "MENU")
		end)
		reset:SetScript("OnEnter", function() reset:SetBackdropColor(1, .82, 0, .8) end)
		reset:SetScript("OnLeave", function() reset:SetBackdropColor(0, 0, 0, .8) end)
	
	local segment = CreateFrame("Button", nil, self)
	self.segment = segment
		segment:SetBackdrop(backdrop)
		segment:SetBackdropColor(0, 0, 0, .5)
		segment:SetNormalFontObject(ChatFontSmall)
		segment:SetText(" ")
		segment:SetWidth(s.titleheight-2)
		segment:SetHeight(s.titleheight-2)
		segment:SetPoint("RIGHT", reset, "LEFT", -2, 0)
		segment:SetScript("OnMouseUp", function() addon.nav.view = 'Sets' addon.nav.set = nil addon:RefreshDisplay() dropdown:Show() end)
		segment:SetScript("OnEnter", function()
			segment:SetBackdropColor(1, .82, 0, .8)
			GameTooltip:SetOwner(segment, "ANCHOR_BOTTOMRIGHT")
			local name = ""
			if addon.nav.set == 'current' then
				name = "Current Fight"
			else
				local set = addon:GetSet(addon.nav.set)
				if set then
					name = set.name
				end
			end
			GameTooltip:AddLine(name)
			GameTooltip:Show()
		end)
		segment:SetScript("OnLeave", function() segment:SetBackdropColor(0, 0, 0, .8) GameTooltip:Hide() end)

	local title = self:CreateTexture(nil, "ARTWORK")
	self.title = title
		title:SetTexture([[Interface\TargetingFrame\UI-StatusBar]])
		title:SetTexCoord(.8, 1, .8, 1)
		title:SetVertexColor(.25, .66, .35, .9)
		title:SetPoint("TOPLEFT", 1, -1)
		title:SetPoint("BOTTOMRIGHT", reset, "BOTTOMLEFT", -1, 0)
	local font = self:CreateFontString(nil, "ARTWORK")
	self.titletext = font
		font:SetJustifyH("LEFT")
		font:SetFont(s.titlefont, s.titlefontsize, "OUTLINE")
		font:SetTextColor(s.titlefontcolor[1], s.titlefontcolor[2], s.titlefontcolor[3], 1)
		font:SetHeight(s.titleheight)
		font:SetPoint("LEFT", title, "LEFT", 4, 0)
		font:SetPoint("RIGHT", segment, "LEFT", -1, 0)

	self.detailAction = noop
	self:SetScript("OnMouseDown", clickFunction)
	self:SetScript("OnMouseWheel", function(self, num)
		addon:Scroll(num)
	end)
end

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

function window:UpdateSegment(segment)
	if not segment then
		self.segment:Hide()
	else
		self.segment:SetText(segment)
		self.segment:Show()
	end
end

function window:SetTitle(name, r, g, b)
	self.title:SetVertexColor(r, g, b, .9)
	self.titletext:SetText(name)
end

function window:GetTitle()
	return self.titletext:GetText()
end

function window:SetScrollPosition(curPos, maxPos)
	if maxPos <= s.maxlines then return end
	local total = s.maxlines*(s.lineheight+s.linegap)
	self.scroll:SetHeight(s.maxlines/maxPos*total)
	self.scroll:SetPoint("TOPLEFT", self.reset, "BOTTOMRIGHT", 2, -1-(curPos-1)/maxPos*total)
	self.scroll:Show()
end

function window:SetBackAction(f)
	backAction = f or noop
end

local SetValues = function(f, c, m)
	f:SetMinMaxValues(0, m)
	f:SetValue(c)
end
local SetIcon = function(f, icon)
	if icon then
		f:SetWidth(s.width-s.lineheight-4)
		f.icon:SetTexture(icon)
		f.icon:Show()
	else
		f:SetWidth(s.width-4)
		f.icon:Hide()
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
		f:SetPoint("TOPRIGHT", self.reset, "BOTTOMRIGHT", 0, -1)
	else
		f:SetPoint("TOPRIGHT", lines[id-1], "BOTTOMRIGHT", 0, -s.linegap)
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
		reset.titletext:SetText("Numeration: Reset Data?")
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
