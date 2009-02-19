local addon = nMeter
local view = {}
addon.views["Standard"] = view
view.first = 1

function view:Init()
	local v = nMeter.types[addon.nav.type]
	local c = v.c
	addon.window:SetTitle(v.name, c[1], c[2], c[3])
end

local backAction = function(f)
	view.first = 1
	addon.nav.view = 'Type'
	addon.nav.type = nil
	addon:RefreshDisplay()
end

local detailAction = function(f)
	addon.nav.view = 'Spell'
	addon.nav.unit = f.unit
	addon:RefreshDisplay()
end

local amountWithPets = function(set, unit, vtype)
	if unit.owner then return end
	local value = unit[vtype]
	if unit.pets then
		for name,v in pairs(unit.pets) do
			local amount = set.unit[name][vtype]
			if amount then
				value = (value or 0) + amount
			end
		end
	end
	return value
end

-- sortfunc
local what = nil
local sorter = function(u1, u2)
	return u1[what] > u2[what]
end

local sorttbl = {}
function view:Update(merge)
	addon.window:SetBackAction(backAction)
	local set = addon:GetSet(addon.nav.set)
	if not set then return end
	
	what = addon.types[addon.nav.type].id
	local total = set[what]
	
	-- compile and sort information table
	sorttbl = wipe(sorttbl)
	local id = 0
	for name,u in pairs(set.unit) do
		if merge then
			local amount = amountWithPets(set, u, what)
			if amount then
				id = id + 1
				u.merged = amount
				sorttbl[id] = u
			end
		elseif u[what] then
			id = id + 1
			sorttbl[id] = u
		end
	end
	if merge then
		what = 'merged'
	end
	table.sort(sorttbl, sorter)
	
	-- display
	self.first, self.last = addon:GetArea(self.first, #sorttbl)
	if not self.last then return end

	local maxvalue = sorttbl[1][what]
	for i = self.first, self.last do
		local u = sorttbl[i]
		local line = addon.window:GetLine(i-self.first)
		local value = u[what]
		local c = addon.color[u.class]
		
		line:SetValues(value, maxvalue)
		if u.owner then
			line:SetLeftText("%i. %s <%s>", i, u.name, u.owner)
		else
			line:SetLeftText("%i. %s", i, u.name)
		end
		line:SetRightText("%i (%02.1f%%)", value, value/total*100)
		line:SetColor(c[1], c[2], c[3])
		line.unit = u
		line:SetDetailAction(detailAction)
		line:Show()
	end
	
	-- cleanup
	if merge then
		for i,v in ipairs(sorttbl) do
			v.merged = nil
		end
	end
end
