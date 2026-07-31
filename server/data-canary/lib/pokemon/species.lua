PokemonSpecies = {
	byId = {},
	byName = {},
}

local requiredFields = { "id", "name", "types", "baseStats", "gender", "catchRate", "baseExperience" }
local classifications = { normal = true, legendary = true }

local function assertInteger(value, label)
	assert(type(value) == "number" and value % 1 == 0, label .. " must be an integer")
end

local habitatNames = {
	routes = true,
	forests = true,
	caves = true,
	mountains = true,
	waters = true,
	power_plant = true,
	pokemon_tower = true,
	safari_zone = true,
	legendary = true,
}

local legendarySpecies = {
	[144] = true, [145] = true, [146] = true, [150] = true, [151] = true,
}

local safariSpecies = {
	[29] = true, [30] = true, [31] = true, [32] = true, [33] = true, [34] = true,
	[46] = true, [47] = true, [48] = true, [49] = true, [102] = true, [103] = true,
	[111] = true, [112] = true, [113] = true, [115] = true, [123] = true, [127] = true,
	[128] = true,
}

local towerSpecies = {
	[92] = true, [93] = true, [94] = true, [104] = true, [105] = true,
}

local powerPlantSpecies = {
	[25] = true, [26] = true, [81] = true, [82] = true, [100] = true, [101] = true,
	[125] = true, [145] = true,
}

local function containsType(species, wanted)
	for _, pokemonType in ipairs(species.types) do
		if pokemonType == wanted then
			return true
		end
	end
	return false
end

local function inferHabitats(species)
	local result, present = {}, {}
	local function add(name)
		if not present[name] then
			table.insert(result, name)
			present[name] = true
		end
	end

	if containsType(species, "water") or species.id == 131 then add("waters") end
	if containsType(species, "rock") or containsType(species, "ground") then
		add("caves")
		add("mountains")
	end
	if containsType(species, "bug") or containsType(species, "grass") then add("forests") end
	if containsType(species, "flying") or containsType(species, "normal") or containsType(species, "poison") then add("routes") end
	if towerSpecies[species.id] then add("pokemon_tower") end
	if powerPlantSpecies[species.id] then add("power_plant") end
	if safariSpecies[species.id] then add("safari_zone") end
	if legendarySpecies[species.id] then add("legendary") end
	if #result == 0 then add("routes") end
	return result
end

local function normalizeBestiary(species)
	local bestiary = species.bestiary or {}
	bestiary.raceId = bestiary.raceId or (10000 + species.id)
	bestiary.region = bestiary.region or "kanto"
	bestiary.habitats = bestiary.habitats or inferHabitats(species)
	bestiary.toKill = bestiary.toKill or 500
	bestiary.firstUnlock = bestiary.firstUnlock or 10
	bestiary.secondUnlock = bestiary.secondUnlock or 100
	bestiary.charmsPoints = bestiary.charmsPoints or 5
	bestiary.stars = bestiary.stars or 2
	bestiary.occurrence = bestiary.occurrence or 0
	bestiary.locations = bestiary.locations or "Kanto"

	assertInteger(bestiary.raceId, "bestiary.raceId")
	assert(bestiary.raceId > 0 and bestiary.raceId <= 65535, "bestiary.raceId must fit uint16")
	assert(bestiary.region == "kanto", "Gen 1 catalog species must use region 'kanto'")
	assert(type(bestiary.habitats) == "table" and #bestiary.habitats > 0, "bestiary.habitats must not be empty")
	for _, habitat in ipairs(bestiary.habitats) do
		assert(habitatNames[habitat], "unknown Kanto habitat '" .. tostring(habitat) .. "'")
	end
	species.bestiary = bestiary
end

function PokemonSpecies.register(species)
	assert(type(species) == "table", "Pokemon species must be a table")
	for _, field in ipairs(requiredFields) do
		assert(species[field] ~= nil, string.format("Pokemon species is missing '%s'", field))
	end

	assertInteger(species.id, "species.id")
	assert(species.id > 0, "species.id must be positive")
	assert(type(species.name) == "string" and species.name ~= "", "species.name must be non-empty")
	species.classification = species.classification or "normal"
	assert(classifications[species.classification], "unknown Pokemon classification " .. tostring(species.classification))
	assert(#species.types >= 1 and #species.types <= 2, "species.types must contain one or two types")
	assert(species.gender.male + species.gender.female + species.gender.genderless == 1000, "gender weights must total 1000")

	for _, stat in ipairs(PokemonConstants.STAT_KEYS) do
		assertInteger(species.baseStats[stat], "baseStats." .. stat)
		assert(species.baseStats[stat] > 0, "baseStats." .. stat .. " must be positive")
	end

	local normalizedName = species.name:lower()
	assert(not PokemonSpecies.byId[species.id], "duplicate Pokemon species id " .. species.id)
	assert(not PokemonSpecies.byName[normalizedName], "duplicate Pokemon species name " .. species.name)

	species.runtime = species.runtime or {}
	species.runtime.placeholder = species.runtime.placeholder ~= false
	if species.runtime.lookType ~= nil then
		assertInteger(species.runtime.lookType, "runtime.lookType")
		assert(species.runtime.lookType > 0, "runtime.lookType must be positive")
	end
	if species.runtime.placeholder == false then
		assert(species.runtime.lookType ~= nil, "non-placeholder species requires runtime.lookType")
	end
	if PokemonEvolution then
		PokemonEvolution.normalizeSpecies(species)
	end
	normalizeBestiary(species)
	for _, registered in pairs(PokemonSpecies.byId) do
		assert(registered.bestiary.raceId ~= species.bestiary.raceId,
			"duplicate Pokemon bestiary raceId " .. species.bestiary.raceId)
	end
	PokemonSpecies.byId[species.id] = species
	PokemonSpecies.byName[normalizedName] = species
	return species
end

function PokemonSpecies.get(idOrName)
	if type(idOrName) == "number" then
		return PokemonSpecies.byId[idOrName]
	end
	if type(idOrName) == "string" then
		return PokemonSpecies.byName[idOrName:lower()]
	end
	return nil
end

function PokemonSpecies.loadCatalog()
	local files = dofile(DATA_DIRECTORY .. "/lib/pokemon/species/kanto_catalog.lua")
	assert(type(files) == "table" and #files == 151, "Kanto catalog must contain exactly 151 species")
	for _, file in ipairs(files) do
		PokemonSpecies.register(dofile(DATA_DIRECTORY .. "/lib/pokemon/species/" .. file))
	end
	for id = 1, 151 do
		assert(PokemonSpecies.byId[id], string.format("Kanto catalog is missing species #%03d", id))
	end
end
