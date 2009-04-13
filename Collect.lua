local addon = nMeter
local collect = {}
addon.collect = collect

local function addStat(set, unit, stype, amount)
	set[stype] = (set[stype] or 0) + amount
	unit[stype] = (unit[stype] or 0) + amount
end
local function addSpellDetails(u, dtype, spellID, amount)
	if not u.spell then u.spell = {} end
	
	local s = u.spell[spellID]
	if not s then
		s = {
			[dtype] = amount
		}
		u.spell[spellID] = s
	else
		s[dtype] = (s[dtype] or 0) + amount
	end
end
local function addTargetDetails(u, dtype, targetName, amount)
	if not targetName then targetName = 'Unknown' end
	if not u.target then u.target = {} end
	
	local s = u.target[targetName]
	if not s then
		s = {
			[dtype] = amount
		}
		u.target[targetName] = s
	else
		s[dtype] = (s[dtype] or 0) + amount
	end
end

local function DAMAGE(dtype, timestamp, playerID, playerName, targetName, spellID, amount)
	local all, atm = addon:GetSets()

	-- Total Set
	all.changed = true
	local u = addon:GetUnit(all, playerID, playerName)
	addStat(all, u, dtype, amount)
	addSpellDetails(u, dtype, spellID, amount)

	-- Current Set
	if not atm then return end
	atm.changed = true
	local u = addon:GetUnit(atm, playerID, playerName)
	addStat(atm, u, dtype, amount)
	addSpellDetails(u, dtype, spellID, amount)
	addTargetDetails(u, dtype, targetName, amount)
end

local function HEAL(timestamp, playerID, playerName, targetName, spellID, amount, overheal)
	local all, atm = addon:GetSets()

	-- Total Set
	all.changed = true
	local u = addon:GetUnit(all, playerID, playerName)
	if overheal and overheal > 0 then
		amount = amount - overheal
		addStat(all, u, 'oh', overheal)
		addSpellDetails(u, 'oh', spellID, overheal)
	end
	addStat(all, u, 'heal', amount)
	addSpellDetails(u, 'heal', spellID, amount)

	-- Current Set
	if not atm then return end
	atm.changed = true
	local u = addon:GetUnit(atm, playerID, playerName)
	if overheal and overheal > 0 then
		addStat(atm, u, 'oh', overheal)
		addSpellDetails(u, 'oh', spellID, overheal)
		addTargetDetails(u, 'oh', targetName, overheal)
	end
	addStat(atm, u, 'heal', amount)
	addSpellDetails(u, 'heal', spellID, amount)
	addTargetDetails(u, 'heal', targetName, amount)
end

local function DISPEL(timestamp, playerID, playerName, targetName, spellID, extraSpellID, amount)
	local all, atm = addon:GetSets()

	-- Total Set
	all.changed = true
	local u = addon:GetUnit(all, playerID, playerName)
	addStat(all, u, 'dp', amount)
	addSpellDetails(u, 'dp', extraSpellID, amount)

	-- Current Set
	if not atm then return end
	atm.changed = true
	local u = addon:GetUnit(atm, playerID, playerName)
	addStat(atm, u, 'dp', amount)
	addSpellDetails(u, 'dp', extraSpellID, amount)
	addTargetDetails(u, 'dp', targetName, amount)
end

local function MANAGAINS(timestamp, playerID, playerName, targetName, spellID, amount)
	local all, atm = addon:GetSets()

	-- Total Set
	all.changed = true
	local u = addon:GetUnit(all, playerID, playerName)
	addStat(all, u, 'mg', amount)
	addSpellDetails(u, 'mg', spellID, amount)

	-- Current Set
	if not atm then return end
	atm.changed = true
	local u = addon:GetUnit(atm, playerID, playerName)
	addStat(atm, u, 'mg', amount)
	addSpellDetails(u, 'mg', spellID, amount)
	addTargetDetails(u, 'mg', targetName, amount)
end

local function splitDMG(timestamp, srcGUID, srcName, dstGUID, dstName, spellId, amount)
	local srcFriend = addon.guids[srcGUID]
	local dstFriend = addon.guids[dstGUID]
	if srcFriend and dstFriend then
		DAMAGE('ff', timestamp, srcGUID, srcName, dstName, spellId, amount)
		DAMAGE('dt', timestamp, dstGUID, dstName, srcName, spellId, amount)
	elseif srcFriend then
		addon:EnterCombatEvent(timestamp, dstName)
		DAMAGE('dd', timestamp, srcGUID, srcName, dstName, spellId, amount)
	elseif dstFriend then
		addon:EnterCombatEvent(timestamp, srcName)
		DAMAGE('dt', timestamp, dstGUID, dstName, srcName, spellId, amount)
	end
end

-- COMBAT LOG EVENTS --
function collect.SWING_DAMAGE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
	splitDMG(timestamp, srcGUID, srcName, dstGUID, dstName, 6603, amount)
end

--[[ TODO: later when misses tracked
function collect.SWING_MISSED(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType, amountMissed)
	splitDMG(timestamp, srcGUID, srcName, dstGUID, dstName, 6603, 0)
end
]]--

function collect.RANGE_DAMAGE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
	splitDMG(timestamp, srcGUID, srcName, dstGUID, dstName, spellId, amount)
end
collect.SPELL_DAMAGE = collect.RANGE_DAMAGE
collect.SPELL_PERIODIC_DAMAGE = collect.RANGE_DAMAGE

--[[ TODO: later when misses tracked
function collect.RANGE_MISSED(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType, amountMissed)
	splitDMG(timestamp, srcGUID, srcName, dstGUID, dstName, spellId, 0)
end
collect.SPELL_DAMAGE_MISSED = collect.RANGE_MISSED
collect.SPELL_PERIODIC_MISSED = collect.RANGE_MISSED
]]--

function collect.SPELL_HEAL(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overhealing, critical)
	if addon.guids[srcGUID] then
		HEAL(timestamp, srcGUID, srcName, dstName, spellId, amount, overhealing)
	end
end
collect.SPELL_PERIODIC_HEAL = collect.SPELL_HEAL

function collect.SPELL_DISPEL(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool, auraType)
	if addon.guids[srcGUID] then
		DISPEL(timestamp, srcGUID, srcName, dstName, spellId, extraSpellID, 1)
	end
end
-- SPELL_DISPEL_FAILED TODO: later when misses tracked

function collect.SPELL_ENERGIZE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType)
	if addon.guids[dstGUID] and powerType == 0 then
		MANAGAINS(timestamp, dstGUID, dstName, srcName, spellId, amount)
	end
end
collect.SPELL_PERIODIC_ENERGIZE = SPELL_ENERGIZE