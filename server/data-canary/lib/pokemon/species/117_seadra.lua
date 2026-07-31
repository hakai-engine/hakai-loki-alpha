return {
	id = 117,
	name = "Seadra",
	types = { "water" },
	baseStats = {
		hp = 55,
		attack = 65,
		defense = 95,
		specialAttack = 95,
		specialDefense = 45,
		speed = 85,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 75,
	baseExperience = 154,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 230, method = "trade", item = "dragon-scale" },
	evolutions = { { speciesId = 230, method = "trade", item = "dragon-scale" } },
	runtime = { placeholder = false, lookType = 3117, level = 20 },
}
