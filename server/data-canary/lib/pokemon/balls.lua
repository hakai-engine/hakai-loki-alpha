PokemonBalls = PokemonBalls or {}

local definitions = {
	poke_ball = {
		id = "poke_ball",
		emptyItemId = 54267,
		capturedItemId = 54268,
		catchBonus = 0.00,
		guaranteed = false,
		projectileId = 69,
		successEffectId = 250,
		failureEffectId = 251,
	},
	great_ball = {
		id = "great_ball",
		emptyItemId = 54420,
		capturedItemId = 54421,
		catchBonus = 0.20,
		guaranteed = false,
		projectileId = 69,
		successEffectId = 250,
		failureEffectId = 251,
	},
	super_ball = {
		id = "super_ball",
		emptyItemId = 54422,
		capturedItemId = 54423,
		catchBonus = 0.30,
		guaranteed = false,
		projectileId = 69,
		successEffectId = 250,
		failureEffectId = 251,
	},
	ultra_ball = {
		id = "ultra_ball",
		emptyItemId = 54424,
		capturedItemId = 54425,
		catchBonus = 0.40,
		guaranteed = false,
		projectileId = 69,
		successEffectId = 250,
		failureEffectId = 251,
	},
}

local byItemId = {}

for id, definition in pairs(definitions) do
	assert(definition.id == id, string.format("ball definition key mismatch: %s", id))
	assert(not byItemId[definition.emptyItemId], string.format("duplicate empty ball item id: %d", definition.emptyItemId))
	assert(not byItemId[definition.capturedItemId], string.format("duplicate captured ball item id: %d", definition.capturedItemId))
	byItemId[definition.emptyItemId] = { definition = definition, state = "empty" }
	byItemId[definition.capturedItemId] = { definition = definition, state = "captured" }
end

function PokemonBalls.get(id)
	return definitions[id]
end

function PokemonBalls.fromItemId(itemId)
	return byItemId[itemId]
end

function PokemonBalls.isEmptyItem(itemId)
	local entry = byItemId[itemId]
	return entry ~= nil and entry.state == "empty"
end

function PokemonBalls.isCapturedItem(itemId)
	local entry = byItemId[itemId]
	return entry ~= nil and entry.state == "captured"
end

function PokemonBalls.calculateChance(baseRate, ballId, additionalBonus)
	local definition = definitions[ballId]
	assert(definition, string.format("unknown ball type: %s", tostring(ballId)))
	if definition.guaranteed then
		return 1.0
	end

	local rate = math.max(0, tonumber(baseRate) or 0)
	local bonus = definition.catchBonus + math.max(0, tonumber(additionalBonus) or 0)
	return math.min(rate * (1 + bonus), 0.999999)
end
