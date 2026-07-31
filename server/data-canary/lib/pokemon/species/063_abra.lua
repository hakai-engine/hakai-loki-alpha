return {
	id = 63,
	name = "Abra",
	types = { "psychic" },
	baseStats = {
		hp = 25,
		attack = 20,
		defense = 15,
		specialAttack = 105,
		specialDefense = 55,
		speed = 90,
	},
	gender = { male = 750, female = 250, genderless = 0 },
	catchRate = 200,
	baseExperience = 62,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 64, method = "level-up", level = 16 },
	evolutions = { { speciesId = 64, method = "level-up", level = 16 } },
	runtime = { placeholder = false, lookType = 3063, level = 5 },
}
