local addon = nMeter
local view = {}
addon.views["Standard"] = view
view.first = 1

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

function view:Init()
	local v = nMeter.types[addon.nav.type]
	local c = v.c
	addon.window:SetTitle(v.name, c[1], c[2], c[3])
	addon.window:SetBackAction(backAction)
end

local amountWithPets = function(set, unit, vtype, vtypet)
	if unit.owner then return end
	local value, valuet = unit[vtype], unit[vtypet]
	if unit.pets then
		for name,v in pairs(unit.pets) do
			local amount, amountt = set.unit[name][vtype], set.unit[name][vtypet]
			if amount then
				value = (value or 0) + amount
				if amountt and (not valuet or amountt > valuet) then
					valuet = amountt
				end
			end
		end
	end
	return value, valuet
end

-- sortfunc
local what = nil
local sorter = function(u1, u2)
	return u1[what] > u2[what]
end

local sorttbl = {}
function view:Update(merge)
	local set = addon:GetSet(addon.nav.set)
	if not set then return end
	
	what = addon.types[addon.nav.type].id
	local total = set[what]
	local whatt = string.format("%st", what)
	
	-- compile and sort information table
	sorttbl = wipe(sorttbl)
	local id = 0
	for name,u in pairs(set.unit) do
		if merge then
			local amount, amountt = amountWithPets(set, u, what, whatt)
			if amount then
				id = id + 1
				u.merged = amount
				u.mergedt = amountt
				sorttbl[id] = u
			end
		elseif u[what] then
			id = id + 1
			sorttbl[id] = u
		end
	end
	if merge then
		what = 'merged'
		whatt = 'mergedt'
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
		local t = u[whatt]
		local c = addon.color[u.class]
		
		line:SetValues(value, maxvalue)
		if u.owner then
			line:SetLeftText("%i. %s <%s>", i, u.name, u.owner)
		else
			line:SetLeftText("%i. %s", i, u.name)
		end
		if t then
			line:SetRightText("%i (%.1f, %02.1f%%)", value, value/t, value/total*100)
		else
			line:SetRightText("%i (%02.1f%%)", value, value/total*100)
		end
		line:SetColor(c[1], c[2], c[3])
		line.unit = u
		line:SetDetailAction(detailAction)
		line:Show()
	end
	
	-- cleanup
	if merge then
		for i,v in ipairs(sorttbl) do
			v.merged = nil
			v.mergedt = nil
		end
	end
end
