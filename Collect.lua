local addon = nMeter
local collect = {}
addon.collect = collect

local function addStat(set, unit, stype, amount)
	set[stype] = (set[stype] or 0) + amount
	unit[stype] = (unit[stype] or 0) + amount
end
local function addSpellDetails(u, stype, spellID, amount)
	if not u.spell then u.spell = {} end
	
	local s = u.spell[spellID]
	if not s then
		s = {
			[stype] = amount
		}
		u.spell[spellID] = s
	else
		s[stype] = (s[stype] or 0) + amount
	end
end
local function addTargetDetails(u, stype, targetName, amount)
	if not targetName then targetName = 'Unknown' end
	if not u.target then u.target = {} end
	
	local s = u.target[targetName]
	if not s then
		s = {
			[stype] = amount
		}
		u.target[targetName] = s
	else
		s[stype] = (s[stype] or 0) + amount
	end
end

local function EVENT(stype, timestamp, playerID, playerName, targetName, spellID, amount)
	local all, atm = addon:GetSets()

	-- Total Set
	all.changed = true
	local u = addon:GetUnit(all, playerID, playerName)
	addStat(all, u, stype, amount)
	addSpellDetails(u, stype, spellID, amount)

	-- Current Set
	if not atm then return end
	atm.changed = true
	local u = addon:GetUnit(atm, playerID, playerName)
	addStat(atm, u, stype, amount)
	addSpellDetails(u, stype, spellID, amount)
	addTargetDetails(u, stype, targetName, amount)
end

-- COMBAT LOG EVENTS --
function collect.SPELL_DAMAGE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
	local srcFriend = addon.guids[srcGUID]
	local dstFriend = addon.guids[dstGUID]
	if srcFriend and dstFriend then
		EVENT('ff', timestamp, srcGUID, srcName, dstName, spellId, amount)
		EVENT('dt', timestamp, dstGUID, dstName, srcName, spellId, amount)
	elseif srcFriend then
		addon:EnterCombatEvent(timestamp, dstName)
		EVENT('dd', timestamp, srcGUID, srcName, dstName, spellId, amount)
	elseif dstFriend then
		addon:EnterCombatEvent(timestamp, srcName)
		EVENT('dt', timestamp, dstGUID, dstName, srcName, spellId, amount)
	end
end
collect.RANGE_DAMAGE = collect.SPELL_DAMAGE
collect.SPELL_PERIODIC_DAMAGE = collect.SPELL_DAMAGE

function collect.SWING_DAMAGE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
	collect.SPELL_DAMAGE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, 6603, "Attack", 0x01, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
end

--[[ TODO: later when misses tracked
function collect.RANGE_MISSED(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType, amountMissed)
	splitDMG(timestamp, srcGUID, srcName, dstGUID, dstName, spellId, 0)
end
collect.SPELL_DAMAGE_MISSED = collect.RANGE_MISSED
collect.SPELL_PERIODIC_MISSED = collect.RANGE_MISSED

function collect.SWING_MISSED(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType, amountMissed)
	splitDMG(timestamp, srcGUID, srcName, dstGUID, dstName, 6603, 0)
end
]]--

function collect.SPELL_HEAL(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overhealing, critical)
	if addon.guids[srcGUID] then
		if overhealing > 0 then
			amount = amount - overhealing
			EVENT('oh', timestamp, srcGUID, srcName, dstName, spellId, overhealing)
		end
		EVENT('heal', timestamp, srcGUID, srcName, dstName, spellId, amount)
	end
end
collect.SPELL_PERIODIC_HEAL = collect.SPELL_HEAL

function collect.SPELL_DISPEL(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool, auraType)
	if addon.guids[srcGUID] then
		EVENT('dp', timestamp, srcGUID, srcName, dstName, extraSpellID, 1)
	end
end
-- SPELL_DISPEL_FAILED TODO: later when misses tracked

function collect.SPELL_ENERGIZE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType)
	if addon.guids[dstGUID] and powerType == 0 then
		EVENT('mg', timestamp, dstGUID, dstName, srcName, spellId, amount)
	end
end
collect.SPELL_PERIODIC_ENERGIZE = SPELL_ENERGIZE