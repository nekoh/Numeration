local addon = nMeter
local view = {}
addon.views["Type"] = view
view.first = 1

local backAction = function(f)
	view.first = 1
	addon.nav.view = 'Sets'
	addon.nav.set = nil
	addon:RefreshDisplay()
end

local detailAction = function(f)
	addon.nav.view = addon.types[f.typeid].view or 'Standard'
	addon.nav.type = f.typeid
	addon:RefreshDisplay()
end

function view:Init()
	addon.window:SetTitle("Selection: Type", .1, .1, .1)
	addon.window:SetBackAction(backAction)
end

function view:Update()
	local set = addon:GetSet(addon.nav.set)
	if not set then return end
	
	self.first, self.last = addon:GetArea(self.first, #addon.types)
	if not self.last then return end

	for i = self.first, self.last do
		t = addon.types[i]
		local line = addon.window:GetLine(i-self.first)
		local c = t.c
		
		line:SetValues(1, 1)
		line:SetLeftText(" %s", t.name)
		local amount = 0
		for name, u in pairs(set.unit) do
			if u[t.id] then
				amount = amount + u[t.id].total
			end
		end
		if amount ~= 0 then
			line:SetRightText(amount)
		else
			line:SetRightText("")
		end
		line:SetColor(c[1], c[2], c[3])
		line.typeid = i
		line:SetDetailAction(detailAction)
		line:Show()
	end
end
