local addon = select(2, ...)
local view = {}
addon.views["Units"] = view
view.first = 1

local backAction = function(f)
	view.first = 1
	addon.nav.view = 'Type'
	addon.nav.type = nil
	addon:RefreshDisplay()
end

local detailAction = function(f)
	addon.nav.view = 'UnitSpells'
	addon.nav.unit = f.unit
	addon:RefreshDisplay()
end

function view:Init()
	local v = addon.types[addon.nav.type]
	local c = v.c
	addon.window:SetTitle(v.name, c[1], c[2], c[3])
	addon.window:SetBackAction(backAction)
end

local nameToValue = {}
local nameToTime = {}
local calcValueTime = function(set, name, etype, merged)
	local u = set.unit[name]
	local value = u[etype] and u[etype].total or 0
	local time = u[etype] and u[etype].time or 0
	if merged and u.pets then
		for petname,v in pairs(u.pets) do
			local pu_event = set.unit[petname][etype]
			if pu_event then
				value = value + pu_event.total
				if pu_event.time and pu_event.time > time then
					time = pu_event.time
				end
			end
		end
	end
	nameToValue[name] = value
	nameToTime[name] = time
end

local sorter = function(n1, n2)
	return nameToValue[n1] > nameToValue[n2]
end

local sorttbl = {}
function view:Update(merged)
	local set = addon:GetSet(addon.nav.set)
	if not set then return end
	local etype = addon.types[addon.nav.type].id
	
	-- compile and sort information table
	local total = 0
	for name,u in pairs(set.unit) do
		if u[etype] then
			total = total + u[etype].total
		end
		if not merged or not u.owner then
			if u[etype] then
				calcValueTime(set, name, etype, merged)
				tinsert(sorttbl, name)
			elseif merged and u.pets then
				for petname,v in pairs(u.pets) do
					if set.unit[petname][etype] then
						calcValueTime(set, name, etype, merged)
						tinsert(sorttbl, name)
						break
					end
				end
			end
		end
	end
	table.sort(sorttbl, sorter)
	
	-- display
	self.first, self.last = addon:GetArea(self.first, #sorttbl)
	if not self.last then return end
	
	local maxvalue = nameToValue[sorttbl[1]]
	for i = self.first, self.last do
		local u = set.unit[sorttbl[i]]
		local value, time = nameToValue[sorttbl[i]], nameToTime[sorttbl[i]]
		local c = addon.color[u.class]
		
		local line = addon.window:GetLine(i-self.first)
		line:SetValues(value, maxvalue)
		if u.owner then
			line:SetLeftText("%i. %s <%s>", i, u.name, u.owner)
		else
			line:SetLeftText("%i. %s", i, u.name)
		end
		if time ~= 0 then
			line:SetRightText("%i (%.1f, %02.1f%%)", value, value/time, value/total*100)
		else
			line:SetRightText("%i (%02.1f%%)", value, value/total*100)
		end
		line:SetColor(c[1], c[2], c[3])
		line.unit = sorttbl[i]
		line:SetDetailAction(detailAction)
		line:Show()
	end
	
	sorttbl = wipe(sorttbl)
	nameToValue = wipe(nameToValue)
	nameToTime = wipe(nameToTime)
end
