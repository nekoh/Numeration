local addon = nMeter
local view = {}
addon.views["Sets"] = view
view.first = 1

function view:Init()
	addon.window:SetTitle("Selection: Set", .1, .1, .1)
end

local detailAction = function(f)
	addon.nav.view = 'Type'
	addon.nav.set = f.id
	addon:RefreshDisplay()
end

local setLine = function(name, id, lineid)
	local set = addon:GetSet(id)
	local line = addon.window:GetLine(lineid)
	line:SetValues(1, 1)
	if name then
		line:SetLeftText(name)
	else
		local set = 
		line:SetLeftText("%i. %s", id, set.name or 'nil') -- TODO: remove nil when resetting
	end
	line:SetRightText("")
	line:SetColor(.3, .3, .3)
	line.id = id
	line:SetDetailAction(detailAction)
	line:Show()
end

function view:Update()
	addon.window:SetBackAction(nil)

	setLine(" Overall Data", "total", 0)
	setLine(" Current Fight", "current", 1)

	self.first, self.last = addon:GetArea(self.first, #nMeterCharDB+2)
	if not self.last then return end

	for i = self.first, self.last-2 do
		t = nMeterCharDB[i]
		setLine(nil, i, i-self.first+2)
	end

end
