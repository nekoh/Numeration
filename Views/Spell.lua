local addon = nMeter
local view = {}
addon.views["Spell"] = view
view.first = 1

local backAction = function(f)
	view.first = 1
	addon.nav.view = 'Standard'
	addon.nav.unit = nil
	addon:RefreshDisplay()
end

local detailAction = function(f)
	addon.nav.view = 'Target'
	addon:RefreshDisplay()
end

function view:Init()
	local v = addon.types[addon.nav.type]
	local unit = addon.nav.unit
	local text
	if unit.owner then
		text = format("%s: %s <%s>", v.name, unit.name, unit.owner)
	else
		text = format("%s: %s", v.name, unit.name)
	end
	addon.window:SetTitle(text, v.c[1], v.c[2], v.c[3])
	addon.window:SetBackAction(backAction)
end

-- sortfunc
local what = nil
local sorter = function(s1, s2)
	return s1[what] > s2[what]
end

local spellName = addon.spellName
local spellIcon = addon.spellIcon
local sorttbl = {}
function view:Update(merge)
	local set = addon:GetSet(addon.nav.set)
	if not set then return end
	local unit = addon.nav.unit

	what = addon.types[addon.nav.type].id
	local total = unit[what] or 0
	-- sort
	sorttbl = wipe(sorttbl)
	local id = 0
	if unit.spell then
		for spellID,s in pairs(unit.spell) do
			if s[what] then
				id = id + 1
				s.id = spellID
				sorttbl[id] = s
			end
		end
	end
	if merge and unit.pets then
		for name,v in pairs(unit.pets) do
			local u = set.unit[name]
			if u.spell then
				for spellID,s in pairs(u.spell) do
					if s[what] then
						id = id + 1
						s.id = spellID
						s.pet = u.name
						sorttbl[id] = s
						total = total + s[what]
					end
				end
			end
		end
	end
	table.sort(sorttbl, sorter)
	
	local action = nil
	if unit.target then
		action = detailAction
		addon.window:SetDetailAction(action)
	end
	-- display
	self.first, self.last = addon:GetArea(self.first, #sorttbl)
	if not self.last then return end
	
	local c = addon.color[unit.class]
	local maxvalue = sorttbl[1][what]
	for i = self.first, self.last do
		local s = sorttbl[i]
		local line = addon.window:GetLine(i-self.first)
		local value = s[what]
		local name, icon = spellName[s.id], spellIcon[s.id]
		
		if s.id == 0 or s.id == 75 then icon = "" end
		
		line:SetValues(value, maxvalue)
		if s.pet then
			line:SetLeftText("%s <%s>", name, s.pet)
		else
			line:SetLeftText(name)
		end
		line:SetRightText("%i (%02.1f%%)", value, value/total*100)
		line:SetColor(c[1], c[2], c[3])
		line:SetIcon(icon)
		line:SetDetailAction(action)
		line:Show()
	end
	
	-- cleanup
	for i,v in ipairs(sorttbl) do
		v.id = nil
		v.pet = nil
	end
end
