local mType = Game.createMonsterType("Training Stake")
local monster = {}

-- Balanced Pokemon-domain reference used to measure damage. Its large runtime
-- HP only keeps the stake alive between tests; offensive and defensive stats
-- are derived by the same calculator used by wild and summoned Pokemon.
local trainingProfile = {
	level = 50,
	type = "normal",
	nature = "hardy",
	gender = "genderless",
	baseStats = {
		hp = 100,
		attack = 100,
		defense = 100,
		specialAttack = 100,
		specialDefense = 100,
		speed = 100,
	},
	ivs = {
		hp = 31,
		attack = 31,
		defense = 31,
		specialAttack = 31,
		specialDefense = 31,
		speed = 31,
	},
}

monster.description = "a Pokemon combat training stake"
monster.experience = 0
monster.outfit = {
	-- Temporary Canary training-machine appearance. It is already present
	-- in the 15.25 assets and can later be replaced without changing combat.
	lookType = 1142,
}

monster.health = 100000000
monster.maxHealth = monster.health
monster.race = "venom"
monster.corpse = 0
monster.speed = 0

monster.changeTarget = {
	interval = 1000,
	chance = 0,
}

monster.flags = {
	summonable = false,
	attackable = true,
	hostile = false,
	convinceable = false,
	illusionable = false,
	pushable = false,
	canPushItems = false,
	canPushCreatures = false,
	targetDistance = 1,
	staticAttackChance = 0,
	runHealth = 0,
	healthHidden = false,
	isBlockable = true,
}

monster.loot = {}
monster.attacks = {}
monster.defenses = {
	defense = 0,
	armor = 0,
}
monster.elements = {}
monster.immunities = {}

mType.onSpawn = function(spawnedMonster)
	local stats = PokemonStats.calculate(
		{ baseStats = trainingProfile.baseStats },
		trainingProfile.level,
		trainingProfile.ivs,
		trainingProfile.nature,
		trainingProfile.gender
	)
	assert(spawnedMonster:setPokemonCombatProfile(
		trainingProfile.level,
		PokemonTypes.id(trainingProfile.type),
		0,
		stats.attack,
		stats.defense,
		stats.specialAttack,
		stats.specialDefense,
		stats.speed,
		1.0
	), "failed to attach Pokemon profile to Training Stake")
end

mType:register(monster)
