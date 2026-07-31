return {
	id = 10,
	name = "Caterpie",
	types = { "bug" },
	baseStats = {
		hp = 45,
		attack = 30,
		defense = 35,
		specialAttack = 20,
		specialDefense = 20,
		speed = 45,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 255,
	baseExperience = 39,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 11, method = "level-up", level = 7 },
	evolutions = { { speciesId = 11, method = "level-up", level = 7 } },
	runtime = { placeholder = false, lookType = 3010, level = 5 },
}
