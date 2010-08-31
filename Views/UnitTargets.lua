local addon = select(2, ...)
local view = {}
addon.views["UnitTargets"] = view
view.first = 1

local backAction = function(f)
	view.first = 1
	addon.nav.view = 'UnitSpells'
	addon:RefreshDisplay()
end

function view:Init()
	local set = addon:GetSet(addon.nav.set)
	if not set then backAction() return end
	local u = set.unit[addon.nav.unit]
	if not u then backAction() return end
	
	local t = addon.types[addon.nav.type]
	local text
	if u.owner then
		text = format("%s Targets: %s <%s>", t.name, u.name, u.owner)
	else
		text = format("%s Targets: %s", t.name, u.name)
	end
	addon.window:SetTitle(text, t.c[1], t.c[2], t.c[3])
	addon.window:SetBackAction(backAction)
end

local sorttbl = {}
local nameToValue = {}
local nameToUnit = {}
local nameToTarget = {}
local sorter = function(n1, n2)
	return nameToValue[n1] > nameToValue[n2]
end

function view:Update(merged)
	local set = addon:GetSet(addon.nav.set)
	if not set then backAction() return end
	local u = set.unit[addon.nav.unit]
	if not u then backAction() return end
	local etype = addon.types[addon.nav.type].id
	
	-- compile and sort information table
	local total = 0
	if u[etype] then
		total = u[etype].total
		for target, amount in pairs(u[etype].target) do
			local name = format("%s%s", u.name, target)
			nameToValue[name] = amount
			nameToTarget[name] = target
			tinsert(sorttbl, name)
		end
	end
	if merged and u.pets then
		for petname,v in pairs(u.pets) do
			local pu = set.unit[petname]
			if pu[etype] then
				total = total + pu[etype].total
				for target, amount in pairs(pu[etype].target) do
					local name = format("%s%s", pu.name, target)
					nameToValue[name] = amount
					nameToUnit[name] = pu
					nameToTarget[name] = target
					tinsert(sorttbl, name)
				end
			end
		end
	end
	table.sort(sorttbl, sorter)
	
	-- display
	self.first, self.last = addon:GetArea(self.first, #sorttbl)
	if not self.last then return end
	
	local c = addon.color[u.class]
	local maxvalue = nameToValue[sorttbl[1]]
	for i = self.first, self.last do
		local pu = nameToUnit[sorttbl[i]]
		local value = nameToValue[sorttbl[i]]
		local target = nameToTarget[sorttbl[i]]
		
		local line = addon.window:GetLine(i-self.first)
		line:SetValues(value, maxvalue)
		if pu then
			line:SetLeftText("%i. %s <%s>", i, target, pu.name)
		else
			line:SetLeftText("%i. %s", i, target)
		end
		line:SetRightText("%i (%02.1f%%)", value, value/total*100)
		line:SetColor(c[1], c[2], c[3])
		line:SetIcon(icon)
		line:SetDetailAction(nil)
		line:Show()
	end
	
	sorttbl = wipe(sorttbl)
	nameToValue = wipe(nameToValue)
	nameToUnit = wipe(nameToUnit)
	nameToTarget = wipe(nameToTarget)
end
