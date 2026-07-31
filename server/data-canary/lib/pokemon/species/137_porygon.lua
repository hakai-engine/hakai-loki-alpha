return {
	id = 137,
	name = "Porygon",
	types = { "normal" },
	baseStats = {
		hp = 65,
		attack = 60,
		defense = 70,
		specialAttack = 85,
		specialDefense = 75,
		speed = 40,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 45,
	baseExperience = 79,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 233, method = "trade", item = "up-grade" },
	evolutions = { { speciesId = 233, method = "trade", item = "up-grade" } },
	runtime = { placeholder = false, lookType = 3137, level = 5 },
}
