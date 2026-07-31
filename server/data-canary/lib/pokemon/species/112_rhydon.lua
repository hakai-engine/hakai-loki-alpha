return {
	id = 112,
	name = "Rhydon",
	types = { "ground", "rock" },
	baseStats = {
		hp = 105,
		attack = 130,
		defense = 120,
		specialAttack = 45,
		specialDefense = 45,
		speed = 40,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 60,
	baseExperience = 170,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 464, method = "trade", item = "protector" },
	evolutions = { { speciesId = 464, method = "trade", item = "protector" } },
	runtime = { placeholder = false, lookType = 3112, level = 20 },
}
