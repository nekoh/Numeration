--------------------------------------------------------------------------------
-- TODO ------------------------------------------------------------------------
-- manual reset (+ improve automated suggesting)
-- manual petmerge toggle
-- clip title text
-- remove ace
-- window: icon view -> bar does not starts under icon
-- oh %
-- report
-- arenas
-- tracking conditions (improve, fix)
-- ? spell details [crit,miss]
-- ? differentiate between over time- and direct- spells
-- /run SetCVar('uiScale', 768 / 1050)
--------------------------------------------------------------------------------
nMeter = LibStub("AceAddon-3.0"):NewAddon("nMeter", "AceEvent-3.0", "AceTimer-3.0")
nMeter.views = {}
-- important GUIDs
nMeter.guids = {}
nMeter.names = {}

-- SETTINGS
local s = {
	onlybosses = true,
	petsmerged = true,
	refreshinterval = 1,
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
		name = "Damage Targets",
		id = "dd",
		view = "Targets",
		onlyfights = true,
		c = {.25, .66, .35},
	},
	{
		name = "Damage Taken: Targets",
		id = "dt",
		view = "Targets",
		onlyfights = true,
		c = {.66, .25, .25},
	},
	{
		name = "Damage Taken: Abilities",
		id = "dt",
		view = "Spells",
		c = {.66, .25, .25},
	},
	{
		name = "Friendly Fire",
		id = "ff",
		c = {.63, .58, .24},
	},
	{
		name = "Healing",
		id = "hd",
		c = {.25, .5, .85},
	},
	{
		name = "Guessed Absorbs",
		id = "ga",
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
		name = "Interrupts",
		id = "ir",
		c = {.09, .61, .55},
	},
	{
		name = "Mana Gains",
		id = "mg",
		c = {48/255, 113/255, 191/255},
	},
	{
		name = "Death Log",
		id = "deathlog",
		view = "Deathlog",
		onlyfights = true,
		c = {.66, .25, .25},
	},
}

-- Navigation
nMeter.nav = {
	view = 'Units',
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
nMeter.colorhex = {}
do
	for class, c in pairs(nMeter.color) do
		nMeter.colorhex[class] = string.format("%02X%02X%02X", c[1] * 255, c[2] * 255, c[3] * 255)
	end
end

nMeter.spellIcon = setmetatable({ [0] = "", [75] = "", }, { __index = function(tbl, i)
	local spell, _, icon = GetSpellInfo(i)
	nMeter.spellName[i] = spell
	tbl[i] = icon
	return icon
end})
nMeter.spellName = setmetatable({ [0] = "Melee", }, {__index = function(tbl, i)
	local spell, _, icon = GetSpellInfo(i)
	nMeter.spellIcon[i] = icon
	tbl[i] = spell
	return spell
end})
local newSet = function()
	return {
		unit = {},
	}
end
local current

function nMeter:OnInitialize()
	self.window:OnInitialize()
	
	if not nMeterCharDB then
		self:Reset()
	end
	current = self:GetSet(1) or newSet()
	
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	
	self:ZONE_CHANGED_NEW_AREA()
end

function nMeter:Reset()
	local lastZone = nMeterCharDB and nMeterCharDB.zone
	nMeterCharDB = {
		[0] = newSet(),
		zone = lastZone,
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
	self:RefreshDisplay(true)
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
	self.window:SetScrollPosition(first, total)
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

function nMeter:GetUnitClass(playerID)
	if not playerID then return end
	
	local class = self.guids[playerID]
	if self.names[class] then
		return "PET"
	end
	return class
end

function nMeter:GetUnit(set, playerID, playerName)
	if not playerID then
		local u = set.unit[playerName]
		if not u then
			local utotal = nMeterCharDB[0].unit[playerName]
			if utotal then
				u = {
					name = playerName,
					class = utotal.class,
				}
				set.unit[playerName] = u
			end
		end
		return u
	end
	
	local class = self.guids[playerID]
	local ownerName = self.names[class]
	
	if not ownerName then
		-- unit
		local u = set.unit[playerName]
		if not u then
			u = {
				name = playerName,
				class = class,
			}
			set.unit[playerName] = u
		end
		return u
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
		return p, true
	end
end

local summonguids = {}
do
	local UnitGUID, UnitName, UnitClass
		= UnitGUID, UnitName, UnitClass
	local addPlayerPet = function(unit, pet)
		local unitID = UnitGUID(unit)
		if not unitID then return end
		
		local unitName, unitRealm = UnitName(unit)
		local _, unitClass = UnitClass(unit)
		local petID = UnitGUID(pet)
		
		nMeter.guids[unitID] = unitClass
		nMeter.names[unitID] = unitRealm and format("%s-%s", unitName, unitRealm) or unitName
		if petID then
			nMeter.guids[petID] = unitID
		end
	end
	function nMeter:UpdateGUIDS()
		nMeter.names = wipe(nMeter.names)
		nMeter.guids = wipe(nMeter.guids)
		for pid, uid in pairs(summonguids) do
			nMeter.guids[pid] = uid
		end
		
		local num = GetNumRaidMembers()
		if num > 0 then
			for i = 1, num do
				addPlayerPet("raid"..i, "raid"..i.."pet")
			end
		else
			addPlayerPet("player", "pet")
			local num = GetNumPartyMembers()
			if num > 0 then
				for i = 1, num do
					addPlayerPet("party"..i, "party"..i.."pet")
				end
			end
		end
		
		-- remove summons from guid list, if owner is gone
		for pid, uid in pairs(summonguids) do
			if not nMeter.guids[uid] then
				nMeter.guids[pid] = nil
				summonguids[pid] = nil
			end
		end
		self:GUIDsUpdated()
	end
end
nMeter.PLAYER_ENTERING_WORLD = nMeter.UpdateGUIDS
nMeter.PARTY_MEMBERS_CHANGED = nMeter.UpdateGUIDS
nMeter.RAID_ROSTER_UPDATE = nMeter.UpdateGUIDS
nMeter.UNIT_PET = nMeter.UpdateGUIDS
function nMeter:ZONE_CHANGED_NEW_AREA()
	local _, zoneType = IsInInstance()
	print("!ZCNA!", _, zoneType, GetRealZoneText())

	if zoneType ~= self.zoneType then
		self.zoneType = zoneType
		
		if zoneType == "party" or zoneType == "raid" then
			local curZone = GetRealZoneText()
			if curZone ~= nMeterCharDB.zone then
				print("!RESET! ", nMeterCharDB.zone, "->", curZone)
				nMeterCharDB.zone = curZone
				nMeter.window:ShowResetWindow()
			end
			print("!PR! enable events")
			self:UpdateGUIDS()
			
			self:RegisterEvent("PLAYER_ENTERING_WORLD")
			self:RegisterEvent("PARTY_MEMBERS_CHANGED")
			self:RegisterEvent("RAID_ROSTER_UPDATE")
			self:RegisterEvent("UNIT_PET")
			
			self:RegisterEvent("PLAYER_REGEN_DISABLED")
			self:RegisterEvent("PLAYER_REGEN_ENABLED")

			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

			self.updateTimer = self:ScheduleRepeatingTimer("Update", s.refreshinterval)
			self:RefreshDisplay()
			self.window:Show()
		else
			print("!WORLD! disable events")
			self:UnregisterEvent("PLAYER_ENTERING_WORLD")
			self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
			self:UnregisterEvent("RAID_ROSTER_UPDATE")
			self:UnregisterEvent("UNIT_PET")
			
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			self:CancelTimer(self.updateTimer, true)
			if zoneType == "none" then
				self:RefreshDisplay()
				self.window:Show()
			else
				self.window:Hide()
			end
		end
	end
end

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

local bossIds = {
	-- Naxxramas
	[15956] = true, -- Anub'Rekhan
	[15953] = true, -- Grand Widow Faerlina
	[15952] = true, -- Maexxna
	[15954] = true, -- Noth the Plaguebringer
	[15936] = true, -- Heigan the Unclean
	[16011] = true, -- Loatheb
	[16061] = true, -- Instructor Razuvious
	[16060] = true, -- Gothik the Harvester
	[16064] = "The Four Horsemen", -- Thane Korth'azz
	[16065] = "The Four Horsemen", -- Lady Blaumeux
	[30549] = "The Four Horsemen", -- Baron Rivendare
	[16063] = "The Four Horsemen", -- Sir Zeliek
	[16028] = true, -- Patchwerk
	[15931] = true, -- Grobbulus
	[15932] = true, -- Gluth
	[15928] = true, -- Thaddius
	[15989] = true, -- Sapphiron
	[15990] = true, -- Kel'Thuzad
	-- The Eye of Eternity
	[28859] = true, -- Malygos
	-- The Obsidian Sanctum
	[28860] = true, -- Sartharion
	-- Vault of Archavon
	[31125] = true, -- Archavon the Stone Watcher
	[33993] = true, -- Emalon the Storm Watcher
	[35013] = true, -- Koralon the Flame Watcher
	-- Ulduar
	[33113] = true, -- Flame Leviathan
	[33118] = true, -- Ignis the Furnace Master
	[33186] = true, -- Razorscale
	[33293] = true, -- XT-002 Deconstructor
	[32867] = "Assembly of Iron", -- Steelbreaker
	[32927] = "Assembly of Iron", -- Runemaster Molgeim
	[32857] = "Assembly of Iron", -- Stormcaller Brundir
	[32930] = true, -- Kologarn
	[33515] = true, -- Auriaya
	[32906] = true, -- Freya
	[32845] = true, -- Hodir
	[33432] = "Mimiron", -- Leviathan Mk II
	[33651] = "Mimiron", -- VX-001
	[33670] = "Mimiron", -- Aerial Command Unit
	[32865] = true, -- Thorim
	[33271] = true, -- General Vezax
	[33136] = "Yogg-Saron", -- Guardian of Yogg-Saron
	[33288] = true, -- Yogg-Saron
	[32871] = true, -- Algalon the Observer
	-- Trial of the Crusader
	[34796] = "Northrend Beasts", -- Gormok the Impaler
	[35144] = "Northrend Beasts", -- Acidmaw
	[34799] = "Northrend Beasts", -- Dreadscale
	[34797] = "Northrend Beasts", -- Icehowl
	[34780] = true, -- Lord Jaraxxus
	[34469] = "Faction Champions", -- Melador Valestrider <Druid>
	[34459] = "Faction Champions", -- Erin Misthoof <Druid>
	[34465] = "Faction Champions", -- Velanaa <Paladin>
	[34445] = "Faction Champions", -- Liandra Suncaller <Paladin>
	[34466] = "Faction Champions", -- Anthar Forgemender <Priest>
	[34447] = "Faction Champions", -- Caiphus the Stern <Priest>
	[34470] = "Faction Champions", -- Saamul <Shaman>
	[34444] = "Faction Champions", -- Thrakgar <Shaman>
	[34497] = "Twin Val'kyr", -- Fjola Lightbane
	[34496] = "Twin Val'kyr", -- Eydis Darkbane
	[34564] = true, -- Anub'arak
	-- Onyxia's Lair
	[10184] = true, -- Onyxia
	-- Icecrown Citadel
	[36612] = true, -- Lord Marrowgar
	[36855] = true, -- Lady Deathwhisper
	[37813] = true, -- Deathbringer Saurfang
	[36626] = true, -- Festergut
	[36627] = true, -- Rotface
	[36678] = true, -- Professor Putricide
	[37972] = "Blood Prince Council", -- Prince Keleseth
	[37973] = "Blood Prince Council", -- Prince Taldaram
	[37970] = "Blood Prince Council", -- Prince Valanar
	[37955] = true, -- Blood-Queen Lana'thel
	[36789] = true, -- Valithria Dreamwalker
	[37755] = true, -- Sindragosa
	[29983] = true, -- The Lich King
}
function nMeter:EnterCombatEvent(timestamp, guid, name)
	if not current.active then
		current = newSet()
		current.start = timestamp
		current.active = true
	end
	
	current.now = timestamp
	if not current.boss then
		local mobid = bossIds[tonumber(guid:sub(9, 12), 16)]
		if mobid then
			current.name = mobid == true and name or mobid
			current.boss = true
		elseif not current.name then
			current.name = name
		end
	end
	if not inCombat then
		self:CancelTimer(combatTimer, true)
		combatTimer = self:ScheduleTimer("LeaveCombatEvent", s.combatseconds)
	end
end

function nMeter:LeaveCombatEvent()
	if current.active then
		current.active = nil
		if ((current.now - current.start) < s.mincombatlength) or (s.onlybosses and not current.boss) then
			return
		end
		tinsert(nMeterCharDB, 1, current)
		if type(self.nav.set) == "number" then
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

	local ownerClassOrGUID = self.guids[srcGUID]
	if eventtype == 'SPELL_SUMMON' and ownerClassOrGUID then
		local realSrcGUID = self.guids[ownerClassOrGUID] and ownerClassOrGUID or srcGUID
		summonguids[dstGUID] = realSrcGUID
		self.guids[dstGUID] = realSrcGUID
	elseif eventtype == 'UNIT_DIED' and summonguids[srcGUID] then
		summonguids[srcGUID] = nil
		self.guids[srcGUID] = nil
	end
end
