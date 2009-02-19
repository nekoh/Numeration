local addon = nMeter
local view = {}
addon.views["Target"] = view
view.first = 1

function view:Init()
	local v = addon.types[addon.nav.type]
	local unit = addon.nav.unit
	local c = v.c
	local text
	if unit.owner then
		text = format("%s Targets: %s <%s>", v.name, unit.name, unit.owner)
	else
		text = format("%s Targets: %s", v.name, unit.name)
	end
	addon.window:SetTitle(text, c[1], c[2], c[3])
end

local backAction = function(f)
	view.first = 1
	addon.nav.view = 'Spell'
	addon:RefreshDisplay()
end

-- sortfunc
local what = nil
local sorter = function(s1, s2)
	return s1[what] > s2[what]
end

local sorttbl = {}
function view:Update(merge)
	addon.window:SetBackAction(backAction)
	local set = addon:GetSet(addon.nav.set)
	if not set then return end
	local unit = addon.nav.unit

	what = addon.types[addon.nav.type].id
	local total = unit[what]
	-- sort
	sorttbl = wipe(sorttbl)
	local id = 0
	for name,t in pairs(unit.target) do
		if t[what] then
			id = id + 1
			t.name = name
			sorttbl[id] = t
		end
	end
	if merge and unit.pets then
		for name,v in pairs(unit.pets) do
			local u = set.unit[name]
			for name,t in pairs(u.target) do
				if t[what] then
					id = id + 1
					t.name = name
					t.pet = u.name
					sorttbl[id] = t
					total = total + t[what]
				end
			end
		end
	end
	table.sort(sorttbl, sorter)
	
	-- display
	self.first, self.last = addon:GetArea(self.first, #sorttbl)
	if not self.last then return end
	
	local c = addon.color[unit.class]
	local maxvalue = sorttbl[1][what]
	for i = self.first, self.last do
		local t = sorttbl[i]
		local line = addon.window:GetLine(i-self.first)
		local value = t[what]
		
		line:SetValues(value, maxvalue)
		if t.pet then
			line:SetLeftText("%i. %s <%s>", i, t.name, t.pet)
		else
			line:SetLeftText("%i. %s", i, t.name)
		end
		line:SetRightText("%i (%02.1f%%)", value, value/total*100)
		line:SetColor(c[1], c[2], c[3])
		line:SetIcon(icon)
		line:SetDetailAction(nil)
		line:Show()
	end
	
	-- cleanup
	for i,v in ipairs(sorttbl) do
		v.name = nil
		v.pet = nil
	end
end
