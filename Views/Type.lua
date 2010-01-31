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
		line:SetRightText(set[t.id] or "")
		line:SetColor(c[1], c[2], c[3])
		line.typeid = i
		line:SetDetailAction(detailAction)
		line:Show()
	end
end
