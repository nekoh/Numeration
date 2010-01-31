local addon = nMeter
local view = {}
addon.views["Deathlog-Detail"] = view
view.first = 999

local spellIcon = addon.spellIcon
local spellName = addon.spellName
local colorhex = addon.colorhex

local backAction = function(f)
	view.first = 999
	addon.nav.view = 'Deathlog'
	addon.nav.id = nil
	addon:RefreshDisplay()
end

function view:Init()
	local v = nMeter.types[addon.nav.type]
	addon.window:SetTitle(v.name, v.c[1], v.c[2], v.c[3])
	addon.window:SetBackAction(backAction)

	local set = addon:GetSet(addon.nav.set)
	if not set then return end
	local dl = set.deathlog
	if not dl then return end
	local entry = dl[addon.nav.id]
	if not entry then return end
	
	local playerName, class = strsplit("#", entry[0])
	addon.window:SetTitle(format("%s: |cff%s%s|r", v.name, colorhex[class], playerName), v.c[1], v.c[2], v.c[3])
end

local schoolColor = {
	["1"] = "FFFFFF", -- physical		1,1,1
	["2"] = "FFFFA0", -- holy			1,1,0.627
	["4"] = "FF4D00", -- fire			1,0.5,0.5 // 1,0.3,0
	["8"] = "80FF80", -- nature			0.5,1,0.5
	["16"] = "669AE6", -- frost			0.5,0.5,1 // 0.4,0.6,0.9
	["20"] = "D35779", -- frostfire		0.824,0.314,0.471
--	["24"] = "FFFFFF", -- froststorm	
	["32"] = "A100A1", -- shadow		0.628,0,0.628
--	["40"] = "FFFFFF", -- shadowstorm	
--	["48"] = "FFFFFF", -- shadowfrost	
	["64"] = "FFBAFF", -- arcane		1, 0.725, 1
}

local eventColors = {
--[[	DT = {.4, .2, .2},
	HT = {.2, .4, .2},
	AB = {.2, .2, .4},
	AD = {.4, .3, .2},
	X  = {.3, .3, .3}, ]]
--[[	DT = {.66, .25, .25},
	HT = {.25, .66, .35},
	AB = {.25, .5, .85},
	AD = {.63, .58, .24},
	X  = {.58, .24, .63},]]
	DT = {.66, .25, .25},
	HT = {.25, .66, .35},
}
local eventText = {}
eventText.DT = function(event, spellId, srcName, spellSchool, amount, overkill, resisted, blocked, absorbed, modifier)
	overkill = (overkill~="") and string.format("|cff943DA1>%s|r", overkill) or ""
	absorbed = (absorbed~="") and string.format("|cffFFFF00-%s|r", absorbed) or "" -- 1,1,0
	blocked = (blocked~="") and string.format("|cffAAAAAA-%s|r", blocked) or "" -- .66,.66,.66 // 0.5,0,1
	resisted = (resisted~="") and string.format("|cff800080-%s|r", resisted) or "" -- 0.5,0,0.5
	return string.format("|cffFF0000%+7d%s|r%s%s%s%s [%s - |cff%s%s|r]", -tonumber(amount), modifier, overkill, absorbed, blocked, resisted, srcName, schoolColor[spellSchool] or "FFFF00", spellName[spellId])
end
eventText.DM = function(event, spellId, srcName, spellSchool, missType, amountMissed)
	return string.format("  |cffAAAAAA%s|r [%s - |cff%s%s|r]", missType, srcName, schoolColor[spellSchool] or "FFFF00", spellName[spellId])
end
eventText.HT = function(event, spellId, srcName, amount, overhealing, modifier)
	overhealing = (overhealing~="") and string.format("|cff00B480>%i|r", overhealing) or "" -- 0,0.705,0.5 = 00B480 // 4080D9
	return string.format("|cff00FF00%+7d%s|r%s [%s - %s]", amount, modifier, overhealing, srcName, spellName[spellId])
end
eventText.AB = function(event, spellId, modifier, stacks)
	stacks = (stacks~="") and string.format(" (%s)", stacks) or ""
	return string.format("     %s|cff%s[%s]|r%s", modifier, (event == "AB") and "B2B200" or "008080", spellName[spellId], stacks)
end
eventText.AD = eventText.AB
eventText.X = function(event, spellId)
	return "     Death"
end
function view:Update()
	local set = addon:GetSet(addon.nav.set)
	if not set then return end
	local dl = set.deathlog
	if not dl then return end
	local dld = dl[addon.nav.id]
	if not dld then return end
	
	-- display
	self.first, self.last = addon:GetArea(self.first, #dld)
	if not self.last then return end

	for i = self.first, self.last do
		local entry = dld[i]
		local line = addon.window:GetLine(i-self.first)
		
		local rtime, healthpct, spellId, event, info = strsplit("#", entry)
		spellId = tonumber(spellId) or 0
		healthpct = tonumber(healthpct)
		local text = eventText[event](event, spellId, strsplit(":", info))
		local c = eventColors[event]
		local icon = spellIcon[spellId]
		
		if c == nil then
			line:SetValues(100, 100)
			line:SetColor(.2, .2, .2)
		else
			line:SetValues(healthpct, 100)
			line:SetColor(c[1], c[2], c[3])
		end
		line:SetIcon(icon)
		line:SetLeftText("|cffAAAAAA%s|r%s", rtime, text)
		line:SetRightText("%s%%", healthpct)
		line:SetDetailAction(nil)
		line:Show()
	end
end
