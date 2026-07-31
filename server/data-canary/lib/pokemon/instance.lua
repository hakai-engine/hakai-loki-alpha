PokemonInstance = {}

local function copyTable(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = type(value) == "table" and copyTable(value) or value
	end
	return copy
end

function PokemonInstance.createCaptured(encounter, ownerGuid, instanceId)
	assert(type(encounter) == "table", "captured instance requires encounter data")
	assert(PokemonSpecies.get(encounter.speciesId), "captured instance has unknown species")
	assert(type(ownerGuid) == "number" and ownerGuid > 0, "captured instance requires ownerGuid")
	assert(type(instanceId) == "string" and instanceId ~= "", "captured instance requires a persistent unique instanceId")

	local species = assert(PokemonSpecies.get(encounter.speciesId))
	local calculatedStats = PokemonStats.calculate(species, encounter.level, encounter.ivs, encounter.nature, encounter.gender)

	return {
		schemaVersion = PokemonConstants.SCHEMA_VERSION,
		instanceId = instanceId,
		ownerGuid = ownerGuid,
		speciesId = encounter.speciesId,
		gender = encounter.gender,
		nature = assert(encounter.nature, "captured encounter requires its spawn nature"),
		level = encounter.level,
		-- Total cumulative XP must already represent the captured encounter level;
		-- otherwise a level-5 wild Pokemon would incorrectly regress on its first kill.
		experience = PokemonProgression.experienceForLevel(encounter.level),
		currentHp = calculatedStats.hp,
		maxHp = calculatedStats.hp,
		ivs = copyTable(encounter.ivs),
		moves = {},
		origin = {
			method = "capture",
			capturedAt = os.time(),
		},
		state = "ready",
	}
end

function PokemonInstance.validate(instance)
	if type(instance) ~= "table" then
		return false, "instance must be a table"
	end
	if instance.schemaVersion ~= PokemonConstants.SCHEMA_VERSION then
		return false, "unsupported schemaVersion"
	end
	if not PokemonSpecies.get(instance.speciesId) then
		return false, "unknown speciesId"
	end
	if type(instance.instanceId) ~= "string" or not instance.instanceId:match("^%d+$") then
		return false, "missing instanceId"
	end
	if type(instance.ownerGuid) ~= "number" or instance.ownerGuid <= 0 then
		return false, "invalid ownerGuid"
	end
	if not PokemonNatures.isValid(instance.nature) then
		return false, "invalid nature"
	end
	if
		instance.gender ~= PokemonConstants.GENDERS.MALE
		and instance.gender ~= PokemonConstants.GENDERS.FEMALE
		and instance.gender ~= PokemonConstants.GENDERS.GENDERLESS
	then
		return false, "invalid gender"
	end
	if type(instance.level) ~= "number" or instance.level < 1 or instance.level % 1 ~= 0
		or instance.level > PokemonCombatConfig.level.maximum
	then
		return false, "invalid level"
	end
	if type(instance.experience) ~= "number" or instance.experience < 0 or instance.experience % 1 ~= 0
		or instance.experience > PokemonProgression.maximumExperience()
	then
		return false, "invalid experience"
	end
	if type(instance.ivs) ~= "table" then
		return false, "missing IVs"
	end
	for _, stat in ipairs(PokemonConstants.STAT_KEYS) do
		local value = instance.ivs[stat]
		if type(value) ~= "number" or value % 1 ~= 0 or value < PokemonConstants.IV_MIN or value > PokemonConstants.IV_MAX then
			return false, "invalid IV " .. stat
		end
	end
	return true
end
