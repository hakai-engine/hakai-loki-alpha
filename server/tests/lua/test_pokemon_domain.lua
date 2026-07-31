-- Isolated tests for the Pokemon species, encounter and captured-instance domain.
-- Run from the repository root:
-- luajit tests/lua/test_pokemon_domain.lua

local passed, failed, errors = 0, 0, {}

local function test(name, callback)
	local ok, err = pcall(callback)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
		table.insert(errors, { name = name, err = err })
	end
end

local function assertTrue(value, message)
	if not value then
		error(message or "expected a truthy value", 2)
	end
end

local function assertEqual(actual, expected, message)
	if actual ~= expected then
		error(message or string.format("expected %s, got %s", tostring(expected), tostring(actual)), 2)
	end
end

local function assertNear(actual, expected, tolerance, message)
	if math.abs(actual - expected) > tolerance then
		error(message or string.format("expected %.12f, got %.12f", expected, actual), 2)
	end
end

local function readFile(path)
	local file, err = io.open(path, "rb")
	assertTrue(file ~= nil, err)
	local contents = file:read("*a")
	file:close()
	return contents
end

DATA_DIRECTORY = "data-canary"
DIRECTION_NORTH, DIRECTION_EAST, DIRECTION_SOUTH, DIRECTION_WEST = 0, 1, 2, 3
DIRECTION_SOUTHWEST, DIRECTION_SOUTHEAST = 4, 5
DIRECTION_NORTHWEST, DIRECTION_NORTHEAST, DIRECTION_NONE = 6, 7, 8

dofile(DATA_DIRECTORY .. "/lib/pokemon/constants.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/rules.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/combat_config.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/types.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/equipment.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/balls.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/corpses.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/natures.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/stats.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/species.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/encounter.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/progression.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/instance.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/evolution.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/moves.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/capture.lua")
dofile(DATA_DIRECTORY .. "/lib/pokemon/repository.lua")

PokemonSpecies.loadCatalog()
math.randomseed(151)

test("Trainer is a neutral shell and cannot use Tibia combat progression", function()
	local vocations = readFile("data/XML/vocations.xml")
	local trainer = vocations:match('<vocation id="11".-</vocation>')
	assertTrue(trainer ~= nil, "Trainer vocation must exist")
	assertTrue(trainer:find('canCombat="false"', 1, true) ~= nil)
	assertTrue(trainer:find('gaincap="0"', 1, true) ~= nil)
	assertTrue(trainer:find('gainhp="0"', 1, true) ~= nil)
	assertTrue(trainer:find('gainmana="0"', 1, true) ~= nil)
	assertTrue(trainer:find('gainhpamount="0"', 1, true) ~= nil)
	assertTrue(trainer:find('gainmanaamount="0"', 1, true) ~= nil)
	assertTrue(trainer:find('meleeDamage="0.0"', 1, true) ~= nil)
	assertTrue(trainer:find('distDamage="0.0"', 1, true) ~= nil)
end)

test("legendary wild encounters receive the boss profile without mutating captures", function()
	for _, speciesId in ipairs({ 144, 145, 146, 150, 151 }) do
		local species = PokemonSpecies.get(speciesId)
		assertEqual(species.classification, "legendary")
		local encounter = PokemonEncounter.create(speciesId, 5, "wild")
		assertEqual(encounter.level, 100)
		assertNear(encounter.runtimeCombatModifiers.healthMultiplier, 10.0, 0.0001)
		assertNear(encounter.runtimeCombatModifiers.damageMultiplier, 2.0, 0.0001)
		local captured = PokemonInstance.createCaptured(encounter, 1, tostring(900000 + speciesId))
		assertTrue(captured.runtimeCombatModifiers == nil, "captured Pokemon must not persist boss modifiers")
	end
end)

test("base stats are real level-one stats and Pokemon level is their direct multiplier", function()
	local machamp = PokemonSpecies.get(68)
	local ivs = { hp=0,attack=0,defense=0,specialAttack=0,specialDefense=0,speed=0 }
	local levelOne = PokemonStats.calculate(machamp, 1, ivs, "hardy", "male")
	local levelHundred = PokemonStats.calculate(machamp, 100, ivs, "hardy", "male")
	local levelThousand = PokemonStats.calculate(machamp, 1000, ivs, "hardy", "male")
	local overCap = PokemonStats.calculate(machamp, 1001, ivs, "hardy", "male")
	for stat, base in pairs(machamp.baseStats) do
		assertEqual(levelOne[stat], base, "level-one " .. stat .. " must equal the species base stat")
		assertEqual(levelHundred[stat], base * 100, "level-100 " .. stat .. " must be 100 times the species base stat")
		assertEqual(levelThousand[stat], base * 1000, "level-1000 " .. stat .. " must be 1000 times the species base stat")
		assertEqual(overCap[stat], levelThousand[stat], "stats must clamp above the Pokemon level cap")
	end
	local adamant = PokemonStats.calculate(machamp, 1, ivs, "adamant", "male")
	assertEqual(adamant.attack, 143, "final stats round up after nature")
	assertEqual(adamant.specialAttack, 59, "lowered stats also round up")
	local female = PokemonStats.calculate(machamp, 1, ivs, "hardy", "female")
	assertEqual(female.hp, 100, "HP rounds up after the female multiplier")
end)

test("Pokemon XP uses the cumulative level-cubed curve and respects level 1000", function()
    assertEqual(PokemonProgression.experienceForLevel(1), 1)
    assertEqual(PokemonProgression.experienceForLevel(2), 8)
    assertEqual(PokemonProgression.levelForExperience(0), 1)
    assertEqual(PokemonProgression.levelForExperience(7), 1)
    assertEqual(PokemonProgression.levelForExperience(8), 2)
    assertEqual(PokemonProgression.levelForExperience(1000000000), 1000)
    assertEqual(PokemonProgression.levelForExperience(1000000001), 1000)
    assertEqual(PokemonProgression.rate, 1000)
end)

test("Pokemon XP resolves a Canary most-damage Trainer back to its active summon instance", function()
    local originalSummon = PokemonSummon
    local player = {
        getId = function() return 7001 end,
        isPlayer = function() return true end,
    }
    PokemonSummon = {
        getByCreature = function() return nil end,
        get = function(owner)
            assertEqual(owner, player)
            return { creatureId = 7002, instanceId = "instance-7002", playerId = 7001 }
        end,
    }
    local active = PokemonProgression.participantFor(player)
    assertEqual(active.instanceId, "instance-7002")
    PokemonSummon = originalSummon
end)

test("Pokemon world labels use the authoritative species and level", function()
    local captured = PokemonInstance.createCaptured(PokemonEncounter.create(1, 5), 42, "3000")
    local calls = {}
    local monster = { setName = function(_, name, description) calls.name, calls.description = name, description return true end }
    assertTrue(PokemonEncounter.applyDisplayName(monster, captured))
    assertEqual(calls.name, "Bulbasaur [Lv. 5]")
    assertEqual(calls.description, "a bulbasaur [lv. 5]")
end)

test("Pokemon XP preserves HP ratio while recalculating level-based stats", function()
    local instance = PokemonInstance.createCaptured(PokemonEncounter.create(4, 1), 42, "3001")
    instance.currentHp = math.floor(instance.maxHp / 2)
    local progressed, details = PokemonProgression.applyExperience(instance, 7)
    assertEqual(details.gained, 7)
    assertTrue(details.leveledUp)
    assertEqual(progressed.level, 2)
    assertEqual(progressed.experience, 8)
    assertEqual(progressed.maxHp, instance.maxHp * 2)
    assertNear(progressed.currentHp / progressed.maxHp, instance.currentHp / instance.maxHp, 0.02)
end)

test("captured Pokemon keeps the cumulative XP implied by its encounter level", function()
    local instance = PokemonInstance.createCaptured(PokemonEncounter.create(4, 5), 42, "3002")
    assertEqual(instance.level, 5)
    assertEqual(instance.experience, PokemonProgression.experienceForLevel(5))
    instance.experience = 0 -- legacy rows are normalized safely on their next load.
    assertTrue(PokemonProgression.normalizeExperience(instance))
    assertEqual(instance.experience, PokemonProgression.experienceForLevel(5))
end)

test("legacy zero HP is rebuilt from authoritative species stats", function()
	local instance = {
		speciesId = 7,
		level = 5,
		nature = "hardy",
		ivs = { hp=0,attack=0,defense=0,specialAttack=0,specialDefense=0,speed=0 },
		currentHp = 0,
		maxHp = 0,
		state = "ready",
	}
	local changed = PokemonRepository.normalizeVitals(instance)
	local expected = PokemonStats.calculate(PokemonSpecies.get(7), 5, instance.ivs, instance.nature).hp
	assertTrue(changed)
	assertEqual(instance.currentHp, expected)
	assertEqual(instance.maxHp, expected)
	assertEqual(instance.state, "ready")
end)

test("valid fainted HP is not revived by normalization", function()
	local ivs = { hp=0,attack=0,defense=0,specialAttack=0,specialDefense=0,speed=0 }
	local maximumHp = PokemonStats.calculate(PokemonSpecies.get(7), 5, ivs, "hardy").hp
	local instance = {
		speciesId = 7,
		level = 5,
		nature = "hardy",
		ivs = ivs,
		currentHp = 0,
		maxHp = maximumHp,
		state = "fainted",
	}
	assertEqual(PokemonRepository.normalizeVitals(instance), false)
	assertEqual(instance.currentHp, 0)
	assertEqual(instance.maxHp, maximumHp)
	assertEqual(instance.state, "fainted")
end)

test("Poke Ball registry resolves item states and catch bonus", function()
	local definition = PokemonBalls.get("poke_ball")
	assertEqual(definition.emptyItemId, 54267)
	assertEqual(definition.capturedItemId, 54268)
	assertEqual(definition.projectileId, 69)
	assertEqual(definition.successEffectId, 250)
	assertEqual(definition.failureEffectId, 251)
	assertTrue(PokemonBalls.isEmptyItem(54267))
	assertTrue(PokemonBalls.isCapturedItem(54268))
	assertNear(PokemonBalls.calculateChance(0.10, "poke_ball", 0), 0.10, 0.000001)
	assertNear(PokemonBalls.calculateChance(0.10, "poke_ball", 0.10), 0.11, 0.000001)
end)

test("Gen 1 corpse registry is contiguous and reversible", function()
	assertEqual(PokemonCorpses.itemIdForSpecies(1), 54269)
	assertEqual(PokemonCorpses.itemIdForSpecies(4), 54272)
	assertEqual(PokemonCorpses.itemIdForSpecies(151), 54419)
	assertEqual(PokemonCorpses.speciesIdForItem(54269), 1)
	assertEqual(PokemonCorpses.speciesIdForItem(54419), 151)
	assertEqual(PokemonCorpses.speciesIdForItem(5990), nil)
end)

test("catalog registers all three complete Kanto starter lines", function()
	assertEqual(PokemonSpecies.get(1).name, "Bulbasaur")
	assertEqual(PokemonSpecies.get(2).evolution.speciesId, 3)
	assertEqual(PokemonSpecies.get(3).evolution, nil)
	assertEqual(PokemonSpecies.get("CHARMANDER").id, 4)
	assertEqual(PokemonSpecies.get(5).evolution.level, 36)
	assertEqual(PokemonSpecies.get(6).types[2], "flying")
	assertEqual(PokemonSpecies.get("Squirtle").id, 7)
	assertEqual(PokemonSpecies.get(8).evolution.speciesId, 9)
	assertEqual(PokemonSpecies.get(9).evolution, nil)
	assertEqual(#PokemonSpecies.byId, 151)
	for speciesId = 1, 9 do
		local species = PokemonSpecies.get(speciesId)
		assertEqual(species.runtime.placeholder, false)
		assertEqual(species.runtime.lookType, 3000 + speciesId)
	end
end)

test("wild encounter rolls permanent pre-capture attributes", function()
	local encounter = PokemonEncounter.create(1, 5)
	assertEqual(encounter.speciesId, 1)
	assertEqual(encounter.level, 5)
	assertTrue(PokemonNatures.isValid(encounter.nature), "nature must be fixed when the wild Pokemon spawns")
	for _, stat in ipairs(PokemonConstants.STAT_KEYS) do
		assertTrue(encounter.ivs[stat] >= 0 and encounter.ivs[stat] <= 31, "IV is outside the legal range")
	end
end)

test("capturable corpse is bound to the eligible Trainer who defeated the wild Pokemon", function()
    local attributes = {}
    local encounter = PokemonEncounter.create(1, 5)
    local corpse = {
        setCustomAttribute = function(_, key, value) attributes[key] = value end,
        getCustomAttribute = function(_, key) return attributes[key] end,
        getId = function() return PokemonCorpses.itemIdForSpecies(1) end,
    }
    local trainerVocation = { getId = function() return PokemonConstants.TRAINER_VOCATION_ID end }
    local trainer = {
        isPlayer = function() return true end,
        getVocation = function() return trainerVocation end,
        getGuid = function() return 42 end,
    }
    local otherTrainer = {
        isPlayer = function() return true end,
        getVocation = function() return trainerVocation end,
        getGuid = function() return 43 end,
    }
    local tibiaVocation = { getId = function() return 4 end }
    local nonTrainer = {
        isPlayer = function() return true end,
        getVocation = function() return tibiaVocation end,
        getGuid = function() return 42 end,
    }

    local marked, reason = PokemonCapture.markCorpse(corpse, encounter, trainer:getGuid())
    assertTrue(marked, reason)
    local restored, readReason = PokemonCapture.readCorpse(corpse)
    assertTrue(restored ~= nil, readReason)
    assertEqual(restored.captureOwnerGuid, 42)
    assertEqual(PokemonCapture.authorize(corpse, trainer), true)
    assertEqual(PokemonCapture.authorize(corpse, otherTrainer), false)
    assertEqual(PokemonCapture.authorize(corpse, nonTrainer), false)
end)

test("identity feature flags produce stable neutral values when disabled", function()
    local previousIvs = PokemonRules.ivsEnabled
    local previousGender = PokemonRules.genderEnabled
    local previousNature = PokemonRules.natureEnabled
    PokemonRules.ivsEnabled = false
    PokemonRules.genderEnabled = false
    PokemonRules.natureEnabled = false

    local encounter = PokemonEncounter.create(1, 5)
    assertEqual(encounter.gender, PokemonConstants.GENDERS.GENDERLESS)
    assertEqual(encounter.nature, "hardy")
    for _, stat in ipairs(PokemonConstants.STAT_KEYS) do
        assertEqual(encounter.ivs[stat], 0)
    end

    PokemonRules.ivsEnabled = previousIvs
    PokemonRules.genderEnabled = previousGender
    PokemonRules.natureEnabled = previousNature
end)

test("identity feature flags never reinterpret an existing Pokemon", function()
    local species = PokemonSpecies.get(1)
    local persistedIvs = { hp=31,attack=31,defense=31,specialAttack=31,specialDefense=31,speed=31 }
    local before = PokemonStats.calculate(species, 25, persistedIvs, "adamant", "male")

    local previousIvs = PokemonRules.ivsEnabled
    local previousGender = PokemonRules.genderEnabled
    local previousNature = PokemonRules.natureEnabled
    PokemonRules.ivsEnabled = false
    PokemonRules.genderEnabled = false
    PokemonRules.natureEnabled = false
    local after = PokemonStats.calculate(species, 25, persistedIvs, "adamant", "male")

    for _, stat in ipairs(PokemonConstants.STAT_KEYS) do
        assertEqual(after[stat], before[stat], "feature flags changed persisted " .. stat)
    end

    PokemonRules.ivsEnabled = previousIvs
    PokemonRules.genderEnabled = previousGender
    PokemonRules.natureEnabled = previousNature
end)

test("captured instance receives owner, identity and nature once", function()
	local encounter = PokemonEncounter.create(4, 7)
	local instance = PokemonInstance.createCaptured(encounter, 42, "1001")
	local valid, reason = PokemonInstance.validate(instance)
	assertTrue(valid, reason)
	assertEqual(instance.ownerGuid, 42)
	assertEqual(instance.instanceId, "1001")
	assertTrue(PokemonNatures.isValid(instance.nature))
end)

test("evolution normalizes level, stone and level plus stone routes", function()
    local levelRoute = PokemonEvolution.normalizeRoute({ speciesId = 5, method = "level-up", level = 16 })
    assertEqual(levelRoute.mode, PokemonEvolution.MODES.LEVEL)
    assertEqual(levelRoute.targetSpeciesId, 5)
    assertEqual(levelRoute.executable, true)

    local stoneRoute = PokemonEvolution.normalizeRoute({ targetSpeciesId = 26, mode = "stone", stone = "thunder-stone" })
    assertEqual(stoneRoute.mode, PokemonEvolution.MODES.STONE)
    assertEqual(stoneRoute.executable, true)

    local combinedRoute = PokemonEvolution.normalizeRoute({
        targetSpeciesId = 31,
        mode = "level_stone",
        level = 32,
        stone = "moon-stone",
    })
    assertEqual(combinedRoute.mode, PokemonEvolution.MODES.LEVEL_STONE)
    assertEqual(combinedRoute.executable, true)
end)

test("level evolution is automatic and preserves Pokemon identity", function()
    local instance = PokemonInstance.createCaptured(PokemonEncounter.create(4, 16), 42, "2001")
    instance.currentHp = math.floor(instance.maxHp / 2)
    local route, reason = PokemonEvolution.findEligible(instance, PokemonEvolution.MODES.LEVEL)
    assertTrue(route ~= nil, reason)

    local evolved, evolveReason = PokemonEvolution.apply(instance, route)
    assertTrue(evolved ~= nil, evolveReason)
    assertEqual(evolved.speciesId, 5)
    assertEqual(evolved.instanceId, instance.instanceId)
    assertEqual(evolved.ownerGuid, instance.ownerGuid)
    assertEqual(evolved.gender, instance.gender)
    assertEqual(evolved.nature, instance.nature)
    assertEqual(evolved.experience, instance.experience)
    assertTrue(evolved.currentHp > 0 and evolved.currentHp < evolved.maxHp)
end)

test("stone and level plus stone routes enforce their distinct requirements", function()
    local instance = PokemonInstance.createCaptured(PokemonEncounter.create(25, 5), 42, "2002")
    local stoneRoute = PokemonEvolution.normalizeRoute({
        targetSpeciesId = 26,
        mode = "stone",
        stone = "thunder-stone",
    })
    assertEqual(PokemonEvolution.isEligible(instance, stoneRoute, PokemonEvolution.MODES.STONE, "fire-stone"), false)
    assertEqual(PokemonEvolution.isEligible(instance, stoneRoute, PokemonEvolution.MODES.STONE, "thunder-stone"), true)

    local combinedRoute = PokemonEvolution.normalizeRoute({
        targetSpeciesId = 26,
        mode = "level_stone",
        level = 20,
        stone = "thunder-stone",
    })
    assertEqual(PokemonEvolution.isEligible(instance, combinedRoute, PokemonEvolution.MODES.STONE, "thunder-stone"), false)
    instance.level = 20
    assertEqual(PokemonEvolution.isEligible(instance, combinedRoute, PokemonEvolution.MODES.STONE, "thunder-stone"), true)
end)

test("instance validation rejects invalid identity and IVs", function()
	local encounter = PokemonEncounter.create(6, 36)
	local instance = PokemonInstance.createCaptured(encounter, 42, "1002")
	instance.instanceId = "temporary-id"
	local valid = PokemonInstance.validate(instance)
	assertEqual(valid, false)

	instance.instanceId = "1002"
	instance.ivs.speed = 32
	valid = PokemonInstance.validate(instance)
	assertEqual(valid, false)
end)


test("type chart handles dual types and immunities", function()
    assertNear(PokemonTypes.effectiveness("fire", { "grass", "poison" }), 2, 0.000001)
    assertNear(PokemonTypes.effectiveness("grass", { "fire", "flying" }), 0.25, 0.000001)
    assertNear(PokemonTypes.effectiveness("ground", { "fire", "flying" }), 0, 0.000001)
end)

test("Pokemon type ids remain stable across Lua and native bindings", function()
	local orderedTypes = {
		"normal", "fire", "water", "electric", "grass", "ice",
		"fighting", "poison", "ground", "flying", "psychic", "bug",
		"rock", "ghost", "dragon", "dark", "steel", "fairy",
	}
	for expectedId, typeName in ipairs(orderedTypes) do
		assertEqual(PokemonTypes.id(typeName), expectedId)
	end
end)

test("IV rule changes stats without deleting identity", function()
    local species = PokemonSpecies.get(6)
    local ivs = { hp=31,attack=31,defense=31,specialAttack=31,specialDefense=31,speed=31 }
    local previous = PokemonRules.ivsAffectStats
    PokemonRules.ivsAffectStats = true
    local enabled = PokemonStats.calculate(species, 50, ivs, "hardy")
    PokemonRules.ivsAffectStats = false
    local disabled = PokemonStats.calculate(species, 50, ivs, "hardy")
    assertTrue(enabled.hp > disabled.hp)
    assertEqual(ivs.hp, 31, "toggle must never mutate Pokemon identity")
    PokemonRules.ivsAffectStats = previous
end)

test("nature affects only its declared stats", function()
    local species = PokemonSpecies.get(4)
    local ivs = { hp=0,attack=0,defense=0,specialAttack=0,specialDefense=0,speed=0 }
    local hardy = PokemonStats.calculate(species, 50, ivs, "hardy")
    local adamant = PokemonStats.calculate(species, 50, ivs, "adamant")
    assertTrue(adamant.attack > hardy.attack)
    assertTrue(adamant.specialAttack < hardy.specialAttack)
end)

test("gender buckets apply final damage and HP multipliers", function()
    local species = PokemonSpecies.get(4)
    local ivs = { hp=0,attack=0,defense=0,specialAttack=0,specialDefense=0,speed=0 }
    local base = PokemonStats.calculate(species, 50, ivs, "hardy")
    local male = PokemonStats.calculate(species, 50, ivs, "hardy", "male")
    local female = PokemonStats.calculate(species, 50, ivs, "hardy", "female")
    local genderless = PokemonStats.calculate(species, 50, ivs, "hardy", "genderless")

    assertNear(PokemonCombatConfig.genderDamageMultiplier("male"), 1.10, 0.000001)
    assertNear(PokemonCombatConfig.genderDamageMultiplier("female"), 1.00, 0.000001)
    assertNear(PokemonCombatConfig.genderDamageMultiplier("genderless"), 1.05, 0.000001)
    assertEqual(math.floor(100 * PokemonCombatConfig.genderDamageMultiplier("male")), 110)
    assertEqual(math.floor(100 * PokemonCombatConfig.genderDamageMultiplier("genderless")), 105)
    assertEqual(male.hp, base.hp)
	assertEqual(female.hp, math.ceil(base.hp * 1.10))
	assertEqual(genderless.hp, math.ceil(base.hp * 1.05))
end)

test("gender HP migration preserves current health ratio and faint state", function()
    local species = PokemonSpecies.get(7)
    local ivs = { hp=0,attack=0,defense=0,specialAttack=0,specialDefense=0,speed=0 }
    local oldMaximum = PokemonStats.calculate(species, 50, ivs, "hardy").hp
    local expectedMaximum = PokemonStats.calculate(species, 50, ivs, "hardy", "female").hp
    local instance = {
        speciesId = species.id,
        level = 50,
        gender = "female",
        nature = "hardy",
        ivs = ivs,
        currentHp = math.floor(oldMaximum / 2),
        maxHp = oldMaximum,
        state = "ready",
    }

    assertTrue(PokemonRepository.normalizeVitals(instance))
    assertEqual(instance.maxHp, expectedMaximum)
    assertNear(instance.currentHp / instance.maxHp, math.floor(oldMaximum / 2) / oldMaximum, 0.02)

    instance.currentHp = 0
    instance.maxHp = oldMaximum
    instance.state = "fainted"
    assertTrue(PokemonRepository.normalizeVitals(instance))
    assertEqual(instance.currentHp, 0)
    assertEqual(instance.maxHp, expectedMaximum)
end)

test("move scaling defaults preserve physical and special damage stats", function()
    assertEqual(PokemonMoves.get("tackle").damageScaling, PokemonMoves.DAMAGE_SCALING.ATTACK)
    assertEqual(PokemonMoves.get("ember").damageScaling, PokemonMoves.DAMAGE_SCALING.SPECIAL_ATTACK)
    assertEqual(PokemonMoves.get("ember").powerRule, PokemonMoves.POWER_RULES.FIXED)
    assertEqual(PokemonMoves.attackStatKey({ id="speed_test", damageScaling="user_speed" }), "speed")
end)

test("Electro Ball power follows the canonical faster-than-target tiers", function()
    local move = PokemonMoves.get("electro_ball")
    local defender = { speed=100 }
    assertEqual(PokemonMoves.resolvePower(move, { speed=99 }, defender), 40)
    assertEqual(PokemonMoves.resolvePower(move, { speed=100 }, defender), 60)
    assertEqual(PokemonMoves.resolvePower(move, { speed=200 }, defender), 80)
    assertEqual(PokemonMoves.resolvePower(move, { speed=300 }, defender), 120)
    assertEqual(PokemonMoves.resolvePower(move, { speed=400 }, defender), 150)
    assertEqual(PokemonMoves.resolvePower(move, { speed=999 }, nil), move.power)
end)

test("Gyro Ball power rewards a slower user and respects its cap", function()
    local move = PokemonMoves.get("gyro_ball")
    assertEqual(PokemonMoves.resolvePower(move, { speed=100 }, { speed=100 }), 26)
    assertEqual(PokemonMoves.resolvePower(move, { speed=50 }, { speed=100 }), 51)
    assertEqual(PokemonMoves.resolvePower(move, { speed=10 }, { speed=1000 }), 150)
    assertEqual(PokemonMoves.resolvePower(move, { speed=999 }, nil), move.power)
end)

test("speed-relative pilot moves remain available in complete source learnsets", function()
    local pikachuMoves = PokemonMoves.forSpecies(25)
    local onixMoves = PokemonMoves.forSpecies(95)
    local pikachuById = {}
    for _, move in ipairs(pikachuMoves) do pikachuById[move.id] = move end
    assertEqual(#pikachuMoves, 12)
    assertEqual(pikachuById.electro_ball.damageScaling, "special_attack")
    assertEqual(pikachuById.electro_ball.powerRule, "faster_than_target")
    assertEqual(#onixMoves, 12)
    local gyro = PokemonMoves.get("gyro_ball")
    assertEqual(gyro.damageScaling, "attack")
    assertEqual(gyro.powerRule, "slower_than_target")
    assertEqual(PokemonMoves.get("ember").power, 40)
end)

test("Pikachu pilot covers status, self buff, area and recoil effects", function()
    local moves = {}
    for _, move in ipairs(PokemonMoves.forSpecies(25)) do moves[move.id] = move end
    assertEqual(moves.thunder_wave.category, "status")
    assertEqual(moves.thunder_wave.effects[1].status, "paralysis")
    assertEqual(moves.agility.targetMode, "self")
    assertEqual(moves.agility.effects[1].stages, 2)
    assertEqual(moves.discharge.area, "circle3")
    assertEqual(moves.discharge.areaOrigin, "self")
    assertNear(moves.volt_tackle.effects[2].fraction, 1 / 3, 0.000001)
end)

test("Bulbasaur move set covers damage, status, drain and recovery contracts", function()
    local moves = {}
    for _, move in ipairs(PokemonMoves.forSpecies(1)) do moves[move.id] = move end
    local count = 0
    for _ in pairs(moves) do count = count + 1 end
    assertEqual(count, 12)
    assertEqual(moves.razor_leaf.criticalStage, 1)
    assertEqual(moves.sleep_powder.area, "diamond7")
    assertEqual(moves.sleep_powder.effects[1].status, "sleep")
    assertEqual(moves.poison_powder.effects[1].status, "poison")
    assertEqual(moves.leech_seed.effects[1].kind, "leech_seed")
    assertNear(moves.synthesis.effects[1].fraction, 0.5, 0.000001)
    assertEqual(moves.seed_bomb.category, "physical")
    assertEqual(moves.energy_ball.category, "special")
    assertEqual(moves.sludge_bomb.type, "poison")
    assertEqual(moves.body_slam.jumpHeight, 15)
end)

test("Ivysaur replaces Poison Powder with directional Petal Dance", function()
    local moves = {}
    for _, move in ipairs(PokemonMoves.forSpecies(2)) do moves[move.id] = move end
    local count = 0
    for _ in pairs(moves) do count = count + 1 end
    assertEqual(count, 12)
    assertEqual(moves.poison_powder, nil)
    assertEqual(moves.petal_dance.area, "forward5x4")
    assertEqual(moves.petal_dance.power, 120)
end)

test("Venusaur move set includes its three large-area finishers", function()
    local moves = {}
    for _, move in ipairs(PokemonMoves.forSpecies(3)) do moves[move.id] = move end
    local count = 0
    for _ in pairs(moves) do count = count + 1 end
    assertEqual(count, 12)
    assertEqual(moves.power_whip.areaOrigin, "self")
    assertEqual(moves.petal_blizzard.area, "diamond11")
    assertEqual(moves.hyper_beam.area, "forward3x6")
    assertEqual(moves.hyper_beam.power, 150)
end)

test("basic attack is universal, hidden and uses Pokemon physical stats", function()
    local basic = PokemonMoves.get("basic_attack")
    assertEqual(basic.type, "normal")
    assertEqual(basic.category, "physical")
    assertEqual(basic.range, 1)
    assertEqual(basic.chance, 100)
    assertEqual(basic.basic, true)
    assertEqual(basic.announce, false)

    local visibleMoves = PokemonMoves.forSpecies(1)
    for _, move in ipairs(visibleMoves) do
        assertTrue(move.id ~= "basic_attack", "basic attack must not consume a visible move slot")
    end
end)

test("capture chance derives from species rate and ball contract", function()
    local chance = PokemonCapture.calculateChance(PokemonSpecies.get(6), PokemonBalls.get("poke_ball"), 0)
    assertNear(chance, 0.95, 0.000001)

    local testMinimum = PokemonRules.captureTestMinimumChance
    PokemonRules.captureTestMinimumChance = nil
    local nativeChance = PokemonCapture.calculateChance(PokemonSpecies.get(6), PokemonBalls.get("poke_ball"), 0)
    PokemonRules.captureTestMinimumChance = testMinimum
    assertNear(nativeChance, 45 / 255, 0.000001)
end)

test("capture corpse policy supports single attempt and retry after break", function()
    local original = PokemonRules.captureCorpsePolicy

    PokemonRules.setCaptureCorpsePolicy(PokemonRules.CAPTURE_CORPSE_POLICIES.SINGLE_ATTEMPT)
    assertEqual(PokemonCapture.shouldPreserveCorpseAfterFailure(), false)

    PokemonRules.setCaptureCorpsePolicy(PokemonRules.CAPTURE_CORPSE_POLICIES.RETRY_ON_BREAK)
    assertEqual(PokemonCapture.shouldPreserveCorpseAfterFailure(), true)

    PokemonRules.setCaptureCorpsePolicy(original)
end)

test("Machamp migration uses its real outfit and complete source learnset", function()
    local machamp = PokemonSpecies.get(68)
    assertEqual(machamp.name, "Machamp")
    assertEqual(machamp.runtime.lookType, 3068)
    assertEqual(machamp.runtime.placeholder, false)
    assertEqual(machamp.types[1], "fighting")

    local moves = PokemonMoves.forSpecies(68)
    assertEqual(#moves, 12)
    local ids = {}
    for _, move in ipairs(moves) do ids[move.id] = true end
    assertTrue(ids.brick_break)
    assertTrue(ids.bulk_up)
    assertTrue(ids.close_combat)
    assertTrue(ids.mega_punch)
    assertTrue(ids.mega_kick)
    assertTrue(ids.cross_chop)
    assertTrue(ids.dynamic_punch)
    assertTrue(ids.earthquake)
    assertTrue(ids.focus_blast)
    assertTrue(ids.hyper_beam)
    assertTrue(ids.stone_edge)
    assertTrue(ids.superpower)
end)

test("Venusaur exposes the migrated directional Solar Beam", function()
    local moves = PokemonMoves.forSpecies(3)
    local solar
    for _, move in ipairs(moves) do
        if move.id == "solar_beam" then solar = move end
    end
    assertTrue(solar ~= nil)
    assertEqual(solar.type, "grass")
    assertEqual(solar.category, "special")
    assertEqual(solar.area, "forward3x6")
    assertEqual(solar.power, 120)
end)

print(string.format("%d passed, %d failed", passed, failed))
if #errors > 0 then
	for _, failure in ipairs(errors) do
		print(string.format("FAIL: %s\n  %s", failure.name, failure.err))
	end
	os.exit(1)
end
