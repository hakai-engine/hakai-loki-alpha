PokemonEquipment = { items = {}, sets = {} }

local function emptyBonuses()
	return { stats={}, outgoing={}, resistance={}, allOutgoing=0, allResistance=0, criticalStage=0, criticalDamage=0 }
end

local function merge(target, source)
	if not source then return end
	for stat, value in pairs(source.stats or {}) do target.stats[stat] = (target.stats[stat] or 0) + value end
	for pokemonType, value in pairs(source.outgoing or {}) do target.outgoing[pokemonType] = (target.outgoing[pokemonType] or 0) + value end
	for pokemonType, value in pairs(source.resistance or {}) do target.resistance[pokemonType] = (target.resistance[pokemonType] or 0) + value end
	target.allOutgoing = target.allOutgoing + (source.allOutgoing or 0)
	target.allResistance = target.allResistance + (source.allResistance or 0)
	target.criticalStage = target.criticalStage + (source.criticalStage or 0)
	target.criticalDamage = target.criticalDamage + (source.criticalDamage or 0)
end

function PokemonEquipment.registerItem(itemId, definition)
	assert(type(itemId) == "number" and itemId > 0, "Pokemon equipment requires a valid item id")
	PokemonEquipment.items[itemId] = definition
end

function PokemonEquipment.registerSet(id, definition)
	assert(type(id) == "string" and id ~= "", "Pokemon equipment set requires an id")
	PokemonEquipment.sets[id] = definition
end

function PokemonEquipment.ownerOf(creature)
	if not creature then return nil end
	if creature:isPlayer() then return creature end
	local master = creature:getMaster()
	return master and master:isPlayer() and master or nil
end

function PokemonEquipment.resolve(creature)
	local player, result = PokemonEquipment.ownerOf(creature), emptyBonuses()
	if not player then return result end
	local setCounts = {}
	for slot = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
		local item = player:getSlotItem(slot)
		local definition = item and PokemonEquipment.items[item:getId()]
		if definition then
			merge(result, definition.bonuses)
			if definition.set then setCounts[definition.set] = (setCounts[definition.set] or 0) + 1 end
		end
	end
	for setId, count in pairs(setCounts) do
		local definition = PokemonEquipment.sets[setId]
		if definition then
			for pieces, bonuses in pairs(definition.thresholds or {}) do
				if count >= pieces then merge(result, bonuses) end
			end
		end
	end
	return result
end

function PokemonEquipment.statMultiplier(bonuses, stat)
	return 1 + ((bonuses.stats[stat] or 0) / 100)
end
function PokemonEquipment.outgoingMultiplier(bonuses, pokemonType)
	return 1 + ((bonuses.allOutgoing + (bonuses.outgoing[pokemonType] or 0)) / 100)
end
function PokemonEquipment.resistanceMultiplier(bonuses, pokemonType)
	local reduction = bonuses.allResistance + (bonuses.resistance[pokemonType] or 0)
	return math.max(0, 1 - reduction / 100)
end

-- Example (inactive until real Hakai item IDs are assigned):
-- PokemonEquipment.registerItem(NEW_ID, {set="fire_trainer", bonuses={stats={specialAttack=5}, outgoing={fire=4}}})
-- PokemonEquipment.registerSet("fire_trainer", {thresholds={[2]={resistance={fire=5}}, [4]={outgoing={fire=8}}}})
