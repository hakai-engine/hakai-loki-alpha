PokemonCombatConfig = {
	numericScale = 1,
	level = { minimum = 0, maximum = 1000, effectiveMinimum = 1 },
	-- Development rate. This belongs to Pokemon progression, not Trainer XP.
	progression = { experienceRate = 1000 },
	trainer = { enabled = true, multiplierPerLevel = 0.001 },
	boost = { enabled = true, maximum = 15, divisor = 15, exponent = 1.5 },
	encounterClasses = {
		normal = { wild = { healthMultiplier = 1.00, damageMultiplier = 1.00 } },
		legendary = {
			wild = { level = 100, healthMultiplier = 10.00, damageMultiplier = 2.00 },
		},
	},
	nature = { enabled = true, raised = 1.10, lowered = 0.90 },
	gender = {
		enabled = true,
		buckets = {
			male = { damage = 1.10, hp = 1.00 },
			female = { damage = 1.00, hp = 1.10 },
			genderless = { damage = 1.05, hp = 1.05 },
		},
	},
	actionSpeed = { minimum = 0.25, maximum = 4.00, paralysis = 0.50 },
	critical = {
		enabled = true,
		damageMultiplier = 1.50,
		chanceByStage = { [0] = 416, [1] = 1250, [2] = 5000, [3] = 10000 },
	},
	highImpact = {
		enabled = true,
		minimumDamage = 25,
		targetHealthFraction = 0.20,
		criticalAlwaysTriggers = true,
		shakeIntensity = 4,
		shakeDuration = 180,
		jumpHeight = 8,
		jumpDuration = 180,
	},
}

function PokemonCombatConfig.clampLevel(level)
	local numericLevel = math.floor(tonumber(level) or 0)
	return math.max(PokemonCombatConfig.level.minimum,
		math.min(PokemonCombatConfig.level.maximum, numericLevel))
end

function PokemonCombatConfig.effectiveLevel(level)
	return math.max(PokemonCombatConfig.level.effectiveMinimum,
		PokemonCombatConfig.clampLevel(level))
end

-- Base stats are the real minimum at level 1. Pokemon level itself is the
-- direct multiplier, capped independently from the unlimited trainer level.
function PokemonCombatConfig.levelStatMultiplier(level)
	return PokemonCombatConfig.effectiveLevel(level)
end

function PokemonCombatConfig.encounterClassProfile(classification, context)
	local classConfig = PokemonCombatConfig.encounterClasses[classification or "normal"]
		or PokemonCombatConfig.encounterClasses.normal
	return classConfig[context or "wild"] or PokemonCombatConfig.encounterClasses.normal.wild
end

function PokemonCombatConfig.boostMultiplier(boost)
	if not PokemonCombatConfig.boost.enabled or not PokemonRules.boostAffectsPokemon then return 1 end
	local config = PokemonCombatConfig.boost
	local value = math.max(0, math.min(config.maximum, tonumber(boost) or 0))
	return 1 + math.pow(value / config.divisor, config.exponent)
end

function PokemonCombatConfig.trainerMultiplier(level)
	if not PokemonCombatConfig.trainer.enabled or not PokemonRules.trainerLevelAffectsPokemon then return 1 end
	return 1 + math.max(0, tonumber(level) or 0) * PokemonCombatConfig.trainer.multiplierPerLevel
end

function PokemonCombatConfig.genderBucket(gender)
	return PokemonCombatConfig.gender.buckets[gender]
		or { damage = 1.00, hp = 1.00 }
end

function PokemonCombatConfig.genderDamageMultiplier(gender)
	if not PokemonCombatConfig.gender.enabled or not PokemonRules.genderAffectsDamage then return 1 end
	return PokemonCombatConfig.genderBucket(gender).damage
end

function PokemonCombatConfig.genderHpMultiplier(gender)
	if not PokemonCombatConfig.gender.enabled or not PokemonRules.genderAffectsHp then return 1 end
	return PokemonCombatConfig.genderBucket(gender).hp
end

function PokemonCombatConfig.rollCritical(stage)
	if not PokemonCombatConfig.critical.enabled or not PokemonRules.criticalHitsEnabled then return false end
	stage = math.max(0, math.min(3, tonumber(stage) or 0))
	return math.random(1, 10000) <= PokemonCombatConfig.critical.chanceByStage[stage]
end
