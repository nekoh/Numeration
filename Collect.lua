local addon = nMeter
local collect = {}
addon.collect = collect

local DEATHLOG = false;

local	UnitHealth, UnitHealthMax =
		UnitHealth, UnitHealthMax

local spellName = addon.spellName
local deathlogHealFilter = {
	[spellName[50475]] = true, -- Blood Presence
	[spellName[52042]] = true, -- Healing Stream Totem
	[spellName[20267]] = true, -- Judgement of Light
	[spellName[23880]] = true, -- Bloodthirst
	[spellName[15290]] = true, -- Vampiric Embrace
}
local deathlogTrackBuffs = {
	--DEATHKNIGHT
	[spellName[48707]] = true, -- Anti-Magic Shell
	[spellName[48792]] = true, -- Icebound Fortitude
	[spellName[54223]] = true, -- Shadow of Death
	-- DRUID
	[spellName[22812]] = true, -- Barkskin
	[spellName[61336]] = true, -- Survival Instincts
	-- HUNTER
	[spellName[19263]] = true, -- Deterrence
	[spellName[5384]] = true, -- Feign Death
	-- MAGE
	[spellName[45438]] = true, -- Ice Block
	-- PALADIN
	[spellName[498]] = true, -- Divine Protection
	[spellName[642]] = true, -- Divine Shield
	[spellName[1022]] = true, -- Hand of Protection
	[spellName[1044]] = true, -- Hand of Freedom
	[spellName[1038]] = true, -- Hand of Salvation
	[spellName[19752]] = true, -- Divine Intervention
	--PRIEST
	[spellName[47585]] = true, -- Dispersion
	[spellName[33206]] = true, -- Pain Suppression
	[spellName[47788]] = true, -- Guardian Spirit
	[spellName[27827]] = true, -- Spirit of Redemption
	-- ROGUE
	[spellName[31224]] = true, -- Cloak of Shadows
	[spellName[5277]] = true, -- Evasion
	-- SHAMAN
	[spellName[30823]] = true, -- Shamanistic Rage
	-- WARRIOR
	[spellName[871]] = true, -- Shield Wall
	[spellName[2565]] = true, -- Shield Block
	[spellName[12975]] = true, -- Last Stand
	[spellName[23920]] = true, -- Spell Reflection
}

local deathData = {}
local tblCache = {}
local clearEvts = function(playerID)
	local dd = deathData[playerID]
	if not dd then return end
	for i = dd.first, dd.last do
		local v = dd[i]
		dd[i] = nil
		tinsert(tblCache, table.wipe(v))
	end
	tinsert(tblCache, table.wipe(dd))
	deathData[playerID] = nil
end
local getDeathData = function(guid, timestamp, create)
	local dd = deathData[guid]
	if not dd and not create then
		return
	elseif not dd then
		dd = tremove(tblCache) or {}
		deathData[guid] = dd
	elseif timestamp then
		for i = dd.first, dd.last do
			local v = dd[i]
			if v.t > timestamp-10 then
				break
			end
			dd[i] = nil
			if dd.first < dd.last then
				dd.first = dd.first + 1
			else
				dd.first = nil
				dd.last = nil
			end
			tinsert(tblCache, table.wipe(v))
		end
		if not dd.first and not create then
			tinsert(tblCache, table.wipe(dd))
			deathData[guid] = nil
			return
		end
	end
	return dd
end

local fmtDamage = function(entry)
	local srcName = entry[1]
	local spellId, spellSchool = entry[2], entry[3]
	local amount, overkill = entry[4], entry[5]
	local resisted, blocked, absorbed = entry[6], entry[7], entry[8]
	local critical, glancing, crushing = entry[9], entry[10], entry[11]
	local text = string.format("%i#DT#%s:%i:%i:%s:%s:%s:%s:%s", spellId, srcName or 'Unknown', spellSchool, amount, overkill > 0 and overkill or "", resisted or "", blocked or "", absorbed or "", critical and "!" or glancing and "v" or crushing and "^" or "")
	if overkill > 0 then
		return text, spellId, srcName or 'Unknown', spellSchool, amount
	end
	return text
end
local fmtMiss = function(entry)
	local srcName = entry[1]
	local spellId, spellSchool = entry[2], entry[3]
	local missType, amountMissed = entry[4], entry[5]
	return string.format("%i#DM#%s:%i:%s:%s", spellId, srcName or 'Unknown', spellSchool, missType, amountMissed or '')
end
local fmtHealing = function(entry)
	local srcName = entry[1]
	local spellId = entry[2]
	local amount, overhealing = entry[3], entry[4]
	local critical = entry[5]
	return string.format("%i#HT#%s:%i:%s:%s", spellId, srcName, amount, overhealing > 0 and overhealing or "", critical and "!" or "")
end
local fmtDeBuff = function(entry)
	local spellId = entry[1]
	local auraType = entry[2]
	local amount = entry[3]
	local modifier = entry[4]
	return string.format("%i#A%s#%s:%s", spellId, (auraType == "DEBUFF") and "D" or "B", modifier, amount > 1 and amount or "")
end

local function unitDied(timestamp, playerID, playerName)
	local class = nMeter:GetUnitClass(playerID)
	if not class or class == "PET" then return end
	if class == "HUNTER" and UnitIsFeignDeath(playerName) then return end
	local _, set = addon:GetSets()
	if not set then return end
	set.changed = true
	
	local deathlog = {
		time = timestamp,
	}
	local _spellId, _srcName , _spellSchool, _amount
	local dd = getDeathData(playerID, timestamp)
	if dd then
		for i = dd.first, dd.last do
			local v = dd[i]
			local text, spellId, srcName, spellSchool, amount = v.f(v)
			if spellId then
				_spellId, _srcName , _spellSchool, _amount = spellId, srcName, spellSchool, amount
			end
			tinsert(deathlog, string.format("%0.1f#%.0f#%s", v.t - timestamp, v.hp, text))
			dd[i] = nil
			tinsert(tblCache, table.wipe(v))
		end
		tinsert(tblCache, table.wipe(dd))
		deathData[playerID] = nil
		tinsert(deathlog, "-0.0#0##X#")
	end
	deathlog[0] = string.format("%s#%s#DEATH#%s:%s:%s:%s", playerName, class, _spellId or '', _srcName or '', _spellSchool or '', _amount or '')
	if set.deathlog then
		tinsert(set.deathlog, deathlog)
	else
		set.deathlog = { deathlog, }
	end
	set.dl = (set.dl or 0) + 1
end
local function unitRezzed(timestamp, playerID, playerName, spellId, rezzerName)
	local class = nMeter:GetUnitClass(playerID)
	if not class or class == "PET" then return end
	local _, set = addon:GetSets()
	if not set then return end
	set.changed = true
	
	local deathlog = {
		[0] = string.format("%s#%s#REZZ#%i:%s", playerName, class, spellId, rezzerName),
		time = timestamp,
	}
	if set.deathlog then
		tinsert(set.deathlog, deathlog)
	else
		set.deathlog = { deathlog, }
	end
	set.dl = (set.dl or 0) + 1
	clearEvts(playerID)
end

local addEvt = function(playerID, playerName, fmtFunc, timestamp, ...)
	local class = nMeter:GetUnitClass(playerID)
	if not class or class == "PET" then return end
	local entry = tremove(tblCache) or {}
	entry.hp = ((UnitHealth(playerName)/UnitHealthMax(playerName)) * 100)
	entry.f = fmtFunc
	entry.t = timestamp
	for i = 1, select("#", ...) do
		entry[i] = select(i, ...)
	end
	local dd = getDeathData(playerID, timestamp, true)
	if not dd.first then
		dd.first = 1
		dd.last = 1
	else
		dd.last = dd.last + 1
	end
	dd[dd.last] = entry
	-- hack for DK "Shadow of Death" ghouling
	if fmtFunc == fmtDeBuff and entry[4] == "+" and entry[1] == 54223 then
		unitDied(timestamp, playerID, playerName)
	end
end

function addon:GUIDsUpdated()
	for playerID, dd in pairs(deathData) do
		if not self.guids[playerID] then
			clearEvts(playerID)
		end
	end
end

-- property of RecountGuessedAbsorbs by Elsia
local AbsorbSpellDuration = {
	-- Death Knight
	[48707] = 5, -- Anti-Magic Shell (DK) Rank 1 -- Does not currently seem to show tracable combat log events. It shows energizes which do not reveal the amount of damage absorbed
	[51052] = 10, -- Anti-Magic Zone (DK)( Rank 1 (Correct spellID?)
		-- Does DK Spell Deflection show absorbs in the CL?
	[51271] = 20, -- Unbreakable Armor (DK)
	-- Druid
	[62606] = 10, -- Savage Defense proc. (Druid) Tooltip of the original spell doesn't clearly state that this is an absorb, but the buff does.
	-- Mage
	[11426] = 60, -- Ice Barrier (Mage) Rank 1
	[13031] = 60,
	[13032] = 60,
	[13033] = 60,
	[27134] = 60,
	[33405] = 60,
	[43038] = 60,
	[43039] = 60, -- Rank 8
	[6143] = 30, -- Frost Ward (Mage) Rank 1
	[8461] = 30, 
	[8462] = 30,  
	[10177] = 30,  
	[28609] = 30,
	[32796] = 30,
	[43012] = 30, -- Rank 7
	[1463] = 60, --  Mana shield (Mage) Rank 1
	[8494] = 60,
	[8495] = 60,
	[10191] = 60,
	[10192] = 60,
	[10193] = 60,
	[27131] = 60,
	[43019] = 60,
	[43020] = 60, -- Rank 9
	[543] = 30 , -- Fire Ward (Mage) Rank 1
	[8457] = 30,
	[8458] = 30,
	[10223] = 30,
	[10225] = 30,
	[27128] = 30,
	[43010] = 30, -- Rank 7
	-- Paladin
	[58597] = 6, -- Sacred Shield (Paladin) proc (Fixed, thanks to Julith)
	-- Priest
	[17] = 30, -- Power Word: Shield (Priest) Rank 1
	[592] = 30,
	[600] = 30,
	[3747] = 30,
	[6065] = 30,
	[6066] = 30,
	[10898] = 30,
	[10899] = 30,
	[10900] = 30,
	[10901] = 30,
	[25217] = 30,
	[25218] = 30,
	[48065] = 30,
	[48066] = 30, -- Rank 14
	[47509] = 12, -- Divine Aegis (Priest) Rank 1
	[47511] = 12,
	[47515] = 12, -- Divine Aegis (Priest) Rank 3 (Some of these are not actual buff spellIDs)
	[47753] = 12, -- Divine Aegis (Priest) Rank 1
	[54704] = 12, -- Divine Aegis (Priest) Rank 1
	[47788] = 10, -- Guardian Spirit  (Priest) (50 nominal absorb, this may not show in the CL)
	-- Warlock
	[7812] = 30, -- Sacrifice (warlock) Rank 1
	[19438] = 30,
	[19440] = 30,
	[19441] = 30,
	[19442] = 30,
	[19443] = 30,
	[27273] = 30,
	[47985] = 30,
	[47986] = 30, -- rank 9
	[6229] = 30, -- Shadow Ward (warlock) Rank 1
	[11739] = 30,
	[11740] = 30,
	[28610] = 30,
	[47890] = 30,
	[47891] = 30, -- Rank 6
	-- Consumables
	[29674] = 86400, -- Lesser Ward of Shielding
	[29719] = 86400, -- Greater Ward of Shielding (these have infinite duration, set for a day here :P)
	[29701] = 86400,
	[28538] = 120, -- Major Holy Protection Potion
	[28537] = 120, -- Major Shadow
	[28536] = 120, --  Major Arcane
	[28513] = 120, -- Major Nature
	[28512] = 120, -- Major Frost
	[28511] = 120, -- Major Fire
	[7233] = 120, -- Fire
	[7239] = 120, -- Frost
	[7242] = 120, -- Shadow Protection Potion
	[7245] = 120, -- Holy
	[6052] = 120, -- Nature Protection Potion
	[53915] = 120, -- Mighty Shadow Protection Potion
	[53914] = 120, -- Mighty Nature Protection Potion
	[53913] = 120, -- Mighty Frost Protection Potion
	[53911] = 120, -- Mighty Fire
	[53910] = 120, -- Mighty Arcane
	[17548] = 120, --  Greater Shadow
	[17546] = 120, -- Greater Nature
	[17545] = 120, -- Greater Holy
	[17544] = 120, -- Greater Frost
	[17543] = 120, -- Greater Fire
	[17549] = 120, -- Greater Arcane
	[28527] = 15, -- Fel Blossom
	[29432] = 3600, -- Frozen Rune usage (Naxx classic)
	-- Item usage
	[36481] = 4, -- Arcane Barrier (TK Kael'Thas) Shield
	[57350] = 6, -- Darkmoon Card: Illusion
	[17252] = 30, -- Mark of the Dragon Lord (LBRS epic ring) usage
	[25750] = 15, -- Defiler's Talisman/Talisman of Arathor Rank 1
	[25747] = 15,
	[25746] = 15,
	[23991] = 15,
	[31000] = 300, -- Pendant of Shadow's End Usage
	[30997] = 300, -- Pendant of Frozen Flame Usage
	[31002] = 300, -- Pendant of the Null Rune
	[30999] = 300, -- Pendant of Withering
	[30994] = 300, -- Pendant of Thawing
	[31000] = 300, -- 
	[23506]= 20, -- Arena Grand Master Usage (Aura of Protection)
	[12561] = 60, -- Goblin Construction Helmet usage
	[31771] = 20, -- Runed Fungalcap usage
	[21956] = 10, -- Mark of Resolution usage
	[29506] = 20, -- The Burrower's Shell
	[4057] = 60, -- Flame Deflector
	[4077] = 60, -- Ice Deflector
	[39228] = 20, -- Argussian Compass (may not be an actual absorb)
	-- Item procs
	[27779] = 30, -- Divine Protection - Priest dungeon set 1/2  Proc
	[11657] = 20, -- Jang'thraze (Zul Farrak) proc
	[10368] = 15, -- Uther's Strength proc
	[37515] = 15, -- Warbringer Armor Proc
	[42137] = 86400, -- Greater Rune of Warding Proc
	[26467] = 30, -- Scarab Brooch proc
	[27539] = 6, -- Thick Obsidian Breatplate proc
	[28810] = 30, -- Faith Set Proc Armor of Faith
	[54808] = 12, -- Noise Machine proc Sonic Shield 
	[55019] = 12, -- Sonic Shield (one of these too ought to be wrong)
	[64411] = 15, -- Blessing of the Ancient (Val'anyr Hammer of Ancient Kings equip effect)
	[64413] = 8, -- Val'anyr, Hammer of Ancient Kings proc Protection of Ancient Kings
	-- Misc
	[40322] = 30, -- Teron's Vengeful Spirit Ghost - Spirit Shield
	-- Boss abilities
	[65874] = 15, -- Twin Val'kyr's Shield of Darkness 175000
	[67257] = 15, -- 300000
	[67256] = 15, -- 700000
	[67258] = 15, -- 1200000
	[65858] = 15, -- Twin Val'kyr's Shield of Lights 175000
	[67260] = 15, -- 300000
	[67259] = 15, -- 700000
	[67261] = 15, -- 1200000
}

local function addSpellDetails(u, etype, spellID, amount)
	local event = u[etype]
	if not event then
		event = {
			total=amount,
			spell={},
		}
		u[etype] = event
	else
		event.total = event.total+amount
	end
	
	event.spell[spellID] = (event.spell[spellID] or 0) + amount
end
local function addTargetDetails(u, etype, targetName, amount)
	local t = u[etype].target
	if not t then
		t = {}
		u[etype].target = t
	end
	
	t[targetName] = (t[targetName] or 0) + amount
end

local function EVENT(etype, playerID, playerName, targetName, spellID, amount)
	local all, atm = addon:GetSets()

	-- Total Set
	all.changed = true
	local u = addon:GetUnit(all, playerID, playerName)
	addSpellDetails(u, etype, spellID, amount)

	-- Current Set
	if not atm then return end
	atm.changed = true
	local u = addon:GetUnit(atm, playerID, playerName)
	addSpellDetails(u, etype, spellID, amount)
	addTargetDetails(u, etype, targetName, amount)
end

local function updateTime(u, etype, timestamp)
	local last = u[etype].last
	u[etype].last = now
	if not last then return end
	
	local t = u[etype].time or 0
	local gap = timestamp-last
	if gap < 5 then
		t = t + gap
	else
		t = t + 1
	end
	u[etype].time = t
end
local function TIMEEVENT(etype, timestamp, playerID, playerName)
	local all, atm = addon:GetSets()

	-- Total Set
	updateTime(addon:GetUnit(all, playerID, playerName), etype, timestamp)

	-- Current Set
	if not atm then return end
	updateTime(addon:GetUnit(atm, playerID, playerName), etype, timestamp)
end

local shields = {}
local function findAbsorber(timestamp, dstName, amount)
	if not shields[dstName] then return end
	local mintime = 60
	local shielderName, shieldSpellId
	for shield_id, spells in pairs(shields[dstName]) do
		for shield_src, ts in pairs(spells) do
			local time_diff = ts - timestamp
			if time_diff > -0.1 and time_diff < mintime then
				shielderName = shield_src
				shieldSpellId = shield_id
			else
				spells[shield_src] = nil
			end
		end
	end
	
	if shielderName then
		EVENT('ga', nil, shielderName, dstName, shieldSpellId, amount)
	end
end

-- COMBAT LOG EVENTS --
function collect.SPELL_DAMAGE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
	local srcFriend = addon.guids[srcGUID]
	local dstFriend = addon.guids[dstGUID]
	if dstFriend then
		if srcFriend then
			EVENT('ff', srcGUID, srcName, dstName, spellId, amount)
		else
			addon:EnterCombatEvent(timestamp, srcGUID, srcName)
		end
		EVENT('dt', dstGUID, dstName, srcName, spellId, amount)
		if absorbed then
			findAbsorber(timestamp, dstName, absorbed)
		end
		addEvt(dstGUID, dstName, fmtDamage, timestamp, srcName, spellId, spellSchool, amount, overkill, resisted, blocked, absorbed, critical, glancing, crushing)
	elseif srcFriend then
		addon:EnterCombatEvent(timestamp, dstGUID, dstName)
		EVENT('dd', srcGUID, srcName, dstName, spellId, amount)
		TIMEEVENT('dd', timestamp, srcGUID, srcName)
	end
end
collect.SPELL_PERIODIC_DAMAGE = collect.SPELL_DAMAGE
collect.RANGE_DAMAGE = collect.SPELL_DAMAGE
collect.DAMAGE_SHIELD = collect.SPELL_DAMAGE
function collect.SWING_DAMAGE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
	collect.SPELL_DAMAGE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, 0, "Melee", 0x01, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
	-- Texture: Interface\Icons\INV_Sword_04
end

-- TODO: later when misses tracked, add here
function collect.SPELL_MISSED(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType, amountMissed)
	if addon.guids[dstGUID] then
		addEvt(dstGUID, dstName, fmtMiss, timestamp, srcName, spellId, spellSchool, missType, amountMissed)
		if amountMissed and missType == "ABSORB" then
			findAbsorber(timestamp, dstName, amountMissed)
		end
	end
end
collect.SPELL_PERIODIC_MISSED = collect.SPELL_MISSED
collect.RANGE_MISSED = collect.SPELL_MISSED
collect.DAMAGE_SHIELD_MISSED = collect.SPELL_MISSED
function collect.SWING_MISSED(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType, amountMissed)
	collect.SPELL_MISSED(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, 0, "Melee", 0x01, missType, amountMissed)
end

function collect.SPELL_HEAL(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overhealing, absorbed, critical)
	if addon.guids[srcGUID] then
		if overhealing > 0 then
			EVENT('oh', srcGUID, srcName, dstName, spellId, overhealing)
		end
		EVENT('hd', srcGUID, srcName, dstName, spellId, amount - overhealing)
		TIMEEVENT('hd', timestamp, srcGUID, srcName)
	end
	if addon.guids[dstGUID] and not deathlogHealFilter[spellName] then
		addEvt(dstGUID, dstName, fmtHealing, timestamp, srcName, spellId, amount, overhealing, critical)
	end
end
collect.SPELL_PERIODIC_HEAL = collect.SPELL_HEAL

function collect.SPELL_DISPEL(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool, auraType)
	if addon.guids[srcGUID] then
		EVENT('dp', srcGUID, srcName, dstName, extraSpellID, 1)
	end
end
collect.SPELL_PERIODIC_DISPEL = collect.SPELL_DISPEL
-- SPELL_DISPEL_FAILED TODO: later when misses tracked

function collect.SPELL_INTERRUPT(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool)
	if addon.guids[srcGUID] then
		EVENT('ir', srcGUID, srcName, dstName, extraSpellID, 1)
	end
end


function collect.SPELL_ENERGIZE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType)
	if addon.guids[dstGUID] and powerType == 0 then
		EVENT('mg', dstGUID, dstName, srcName, spellId, amount)
	end
end
collect.SPELL_PERIODIC_ENERGIZE = SPELL_ENERGIZE

function collect.SPELL_AURA_APPLIED_DOSE(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
	if addon.guids[dstGUID] and (auraType == "DEBUFF" or deathlogTrackBuffs[spellName]) then
		addEvt(dstGUID, dstName, fmtDeBuff, timestamp, spellId, auraType, amount or 1, "+")
	end
	local duration = AbsorbSpellDuration[spellId]
	if duration and addon.guids[srcGUID] and addon.guids[dstGUID] then
		shields[dstName] = shields[dstName] or {}
		shields[dstName][spellId] = shields[dstName][spellId] or {}
		shields[dstName][spellId][srcName] = timestamp + duration
	end
end
collect.SPELL_AURA_APPLIED = collect.SPELL_AURA_APPLIED_DOSE
collect.SPELL_AURA_REFRESH = collect.SPELL_AURA_APPLIED_DOSE
collect.SPELL_AURA_REMOVED_DOSE = collect.SPELL_AURA_APPLIED_DOSE
function collect.SPELL_AURA_REMOVED(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType)
	if addon.guids[dstGUID] and (auraType == "DEBUFF" or deathlogTrackBuffs[spellName]) then
		addEvt(dstGUID, dstName, fmtDeBuff, timestamp, spellId, auraType, 1, "-")
	end
	if AbsorbSpellDuration[spellId] and addon.guids[srcGUID] and addon.guids[dstGUID] then
		if shields[dstName] and shields[dstName][spellId] and shields[dstName][spellId][srcName] then
			-- As advised in RecountGuessedAbsorbs, do not remove shields straight away as an absorb can come after the aura removed event.
			shields[dstName][spellId][srcName] = timestamp + 0.1
		end
	end
end

function collect.UNIT_DIED(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags)
	if addon.guids[dstGUID] then
		unitDied(timestamp, dstGUID, dstName)
	end
end

function collect.SPELL_RESURRECT(timestamp, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool)
	if addon.guids[dstGUID] then
		unitRezzed(timestamp, dstGUID, dstName, spellId, srcName)
	end
end
