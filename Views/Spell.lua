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
	local set = addon:GetSet(addon.nav.set)
	if not set then backAction() return end
	local u = set.unit[addon.nav.unit]
	if not u then backAction() return end
	
	local t = addon.types[addon.nav.type]
	local text
	if u.owner then
		text = format("%s: %s <%s>", t.name, u.name, u.owner)
	else
		text = format("%s: %s", t.name, u.name)
	end
	addon.window:SetTitle(text, t.c[1], t.c[2], t.c[3])
	addon.window:SetBackAction(backAction)
end

local sorttbl = {}
local nameToValue = {}
local nameToUnit = {}
local nameToId = {}
local sorter = function(n1, n2)
	return nameToValue[n1] > nameToValue[n2]
end

local spellName = addon.spellName
local spellIcon = addon.spellIcon
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
		for id, amount in pairs(u[etype].spell) do
			local name = format("%s%i", u.name, id)
			nameToValue[name] = amount
			nameToId[name] = id
			tinsert(sorttbl, name)
		end
	end
	if merged and u.pets then
		for petname,v in pairs(u.pets) do
			local pu = set.unit[petname]
			if pu[etype] then
				total = total + pu[etype].total
				for id, amount in pairs(pu[etype].spell) do
					local name = format("%s%i", pu.name, id)
					nameToValue[name] = amount
					nameToUnit[name] = pu
					nameToId[name] = id
					tinsert(sorttbl, name)
				end
			end
		end
	end
	table.sort(sorttbl, sorter)
	
	local action = nil
	if u[etype].target then
		action = detailAction
		addon.window:SetDetailAction(action)
	end
	-- display
	self.first, self.last = addon:GetArea(self.first, #sorttbl)
	if not self.last then return end
	
	local c = addon.color[unit.class]
	local maxvalue = nameToValue[sorttbl[1]]
	for i = self.first, self.last do
		local pu = nameToUnit[sorttbl[i]]
		local value = nameToValue[sorttbl[i]]
		local id = nameToId[sorttbl[i]]
		local name, icon = spellName[id], spellIcon[id]
		
		if id == 0 or id == 75 then icon = "" end
		
		local line = addon.window:GetLine(i-self.first)
		line:SetValues(value, maxvalue)
		if pu then
			line:SetLeftText("%s <%s>", name, pu.name)
		else
			line:SetLeftText(name)
		end
		line:SetRightText("%i (%02.1f%%)", value, value/total*100)
		line:SetColor(c[1], c[2], c[3])
		line:SetIcon(icon)
		line:SetDetailAction(action)
		line:Show()
	end
	
	sorttbl = wipe(sorttbl)
	nameToValue = wipe(nameToValue)
	nameToUnit = wipe(nameToUnit)
	nameToId = wipe(nameToId)
end
