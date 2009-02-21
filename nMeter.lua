--------------------------------------------------------------------------------
-- TODO ------------------------------------------------------------------------
-- reset
-- report
-- only enable tracking under conditions [in instances]
-- only keep boss segments
-- interrupts
-- [dd/dt/heal]-per second
-- spell details [crit,miss]
-- remove ace
-- ? differentiate between over time- and direct- spells
--------------------------------------------------------------------------------
nMeter = LibStub("AceAddon-3.0"):NewAddon("nMeter", "AceEvent-3.0", "AceTimer-3.0")
nMeter.views = {}
-- important GUIDs
nMeter.guids = {}
nMeter.names = {}

-- SETTINGS
local s = {
	refreshinterval = 1,
	petsmerged = true,
	mincombatlength = 15,
	combatseconds = 3,
}
-- available types and their order
nMeter.types = {
	{
		name = "Damage",
		id = "dd",
		c = {.25, .66, .35},
	},
	{
		name = "Damage Taken",
		id = "dt",
		c = {.66, .25, .25},
	},
	{
		name = "Friendly Fire",
		id = "ff",
		c = {0.63, 0.58, 0.24},
	},
	{
		name = "Healing",
		id = "heal",
		c = {.25, .5, .85},
	},
	{
		name = "Overhealing",
		id = "oh",
		c = {.25, .5, .85},
	},
	{
		name = "Dispels",
		id = "dp",
		c = {.58, .24, .63},
	},
	{
		name = "Mana Gains",
		id = "mg",
		c = {48/255, 113/255, 191/255},
	},
}

-- Navigation
nMeter.nav = {
	view = 'Standard',
	set = 'current',
	type = 1,
}

-- used colors
nMeter.color = {
	HUNTER = { 0.67, 0.83, 0.45 },
	WARLOCK = { 0.58, 0.51, 0.79 },
	PRIEST = { 1.0, 1.0, 1.0 },
	PALADIN = { 0.96, 0.55, 0.73 },
	MAGE = { 0.41, 0.8, 0.94 },
	ROGUE = { 1.0, 0.96, 0.41 },
	DRUID = { 1.0, 0.49, 0.04 },
	SHAMAN = { 0.14, 0.35, 1.0 },
	WARRIOR = { 0.78, 0.61, 0.43 },
	DEATHKNIGHT = { 0.77, 0.12, 0.23 },
	PET = { 0.09, 0.61, 0.55 },
}

function nMeter:OnInitialize()
	self.window:OnInitialize()
	
	if not nMeterCharDB then
		self:Reset()
	end
end

function nMeter:OnEnable()
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_PET")
	
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self:RefreshDisplay()
	self:ScheduleRepeatingTimer("Update", s.refreshinterval)
end

local newSet = function(name)
	return {
		name = name,
		unit = {},
	}
end

local current = newSet()
function nMeter:Reset()
	nMeterCharDB = {
		[0] = newSet(),
	}
	current = newSet()
	if self.nav.set and self.nav.set ~= "total" and self.nav.set ~= "current" then
		self.nav.set = "current"
	end
	nMeter:RefreshDisplay()
	collectgarbage("collect")
end

function nMeter:RefreshDisplay(update)
	self.window:Clear()
	
	if not update then
		self.views[self.nav.view]:Init()
	end
	self.views[self.nav.view]:Update(s.petsmerged)
end

function nMeter:Update()
	if not self.nav.set then return end
	
	local set = self:GetSet(self.nav.set)
	if not set or not set.changed then return end
	set.changed = nil
	
	self:RefreshDisplay(true)
end

function nMeter:Scroll(dir)
	local view = self.views[self.nav.view]
	if dir > 0 and view.first > 1 then
		if IsShiftKeyDown() then
			view.first = 1
		else
			view.first = view.first - 1
		end
	elseif dir < 0 then
		if IsShiftKeyDown() then
			view.first = 9999
		else
			view.first = view.first + 1
		end
	end
	nMeter:RefreshDisplay(true)
end

function nMeter:GetArea(start, total)
	if total == 0 then return start end
	
	local first = start
	local last = start+self.window.maxlines-1
	if last > total then
		first = first-last+total
		last = total
	end
	if first < 1 then
		first = 1
	end
	return first, last
end

function nMeter:GetSet(id)
	if not id then return end
	
	if id == 'current' then
		return current
	elseif id == 'total' then
		id = 0
	end
	return nMeterCharDB[id]
end

function nMeter:GetSets()
	return nMeterCharDB[0], current.active and current
end

function nMeter:GetUnit(set, playerID, playerName)
	local class = self.guids[playerID]
	local ownerName = self.names[class]

	if not ownerName then
		-- player
		local p = set.unit[playerName]
		if not p then
			p = {
				name = playerName,
				class = class,
			}
			set.unit[playerName] = p
		end
		return p
	else
		-- pet
		local name = format("%s:%s", ownerName, playerName)
		local p = set.unit[name]
		if not p then
			local ownertable = self:GetUnit(set, class, ownerName)
			if not ownertable.pets then
				ownertable.pets = {}
			end
			ownertable.pets[name] = true

			p = {
				name = playerName,
				class = "PET",
				owner = ownerName,
			}
			set.unit[name] = p
		end
		return p
	end
end

local extraguids = {}
do
	local UnitGUID, UnitName, UnitClass
		= UnitGUID, UnitName, UnitClass
	local addPlayerPet = function(unit, pet)
		local unitID = UnitGUID(unit)
		local unitName = UnitName(unit)
		local _, unitClass = UnitClass(unit)
		local petID = UnitGUID(pet)
		
		nMeter.guids[unitID] = unitClass
		nMeter.names[unitID] = unitName
		if petID then
			nMeter.guids[petID] = unitID
		end
	end
	function nMeter:UpdateGUIDS()
		nMeter.names = wipe(nMeter.names)
		nMeter.guids = wipe(nMeter.guids)
		for pid, uid in pairs(extraguids) do
			nMeter.guids[pid] = uid
		end
		
		local num = GetNumRaidMembers()
		if num > 0 then
			for i = 1, num do
				addPlayerPet("raid"..i, "raid"..i.."pet")
			end
			return
		end
		
		addPlayerPet("player", "pet")
		local num = GetNumPartyMembers()
		if num > 0 then
			for i = 1, num do
				addPlayerPet("party"..i, "party"..i.."pet")
			end
		end
	end
end
nMeter.PLAYER_ENTERING_WORLD = nMeter.UpdateGUIDS
nMeter.PARTY_MEMBERS_CHANGED = nMeter.UpdateGUIDS
nMeter.RAID_ROSTER_UPDATE = nMeter.UpdateGUIDS
nMeter.UNIT_PET = nMeter.UpdateGUIDS

local inCombat = nil
local combatTimer = nil
function nMeter:PLAYER_REGEN_DISABLED()
	inCombat = true
	self:CancelTimer(combatTimer, true)
end
function nMeter:PLAYER_REGEN_ENABLED()
	inCombat = nil
	self:CancelTimer(combatTimer, true)
	combatTimer = self:ScheduleTimer("LeaveCombatEvent", s.combatseconds)
end

function nMeter:EnterCombatEvent(timestamp, name)
	if not current.active then
		current = newSet()
		current.start = timestamp
		current.active = true
	end
	
	current.now = timestamp
	if not current.name then
		current.name = name
		-- TODO: Bossname and stuff
	end
	if not inCombat then
		self:CancelTimer(combatTimer, true)
		combatTimer = self:ScheduleTimer("LeaveCombatEvent", s.combatseconds)
	end
end

function nMeter:LeaveCombatEvent()
	if current.active then
		current.active = nil
		if (current.now - current.start) < s.mincombatlength then
			return
		end
		tinsert(nMeterCharDB, 1, current)
		if self.nav.set and self.nav.set ~= "total" and self.nav.set ~= "current" then
			self.nav.set = self.nav.set + 1
		end
		
		-- Refresh View
		if self.nav.view == 'Sets' then
			self:RefreshDisplay(true)
		end
	end
end

function nMeter:COMBAT_LOG_EVENT_UNFILTERED(e, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if self.collect[eventtype] then
		self.collect[eventtype](timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	end

	if eventtype == 'SPELL_SUMMON' and self.guids[srcGUID] then
		extraguids[dstGUID] = srcGUID
		self.guids[dstGUID] = srcGUID
	elseif eventtype == 'UNIT_DIED' and extraguids[srcGUID] then
		extraguids[srcGUID] = nil
		self.guids[srcGUID] = nil
	end
end
