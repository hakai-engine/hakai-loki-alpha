return {
	id = 96,
	name = "Drowzee",
	types = { "psychic" },
	baseStats = {
		hp = 60,
		attack = 48,
		defense = 45,
		specialAttack = 43,
		specialDefense = 90,
		speed = 42,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 66,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 97, method = "level-up", level = 26 },
	evolutions = { { speciesId = 97, method = "level-up", level = 26 } },
	runtime = { placeholder = false, lookType = 3096, level = 5 },
}
