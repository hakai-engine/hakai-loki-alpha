return {
	id = 11,
	name = "Metapod",
	types = { "bug" },
	baseStats = {
		hp = 50,
		attack = 20,
		defense = 55,
		specialAttack = 25,
		specialDefense = 25,
		speed = 30,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 120,
	baseExperience = 72,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 12, method = "level-up", level = 10 },
	evolutions = { { speciesId = 12, method = "level-up", level = 10 } },
	runtime = { placeholder = false, lookType = 3011, level = 20 },
}
