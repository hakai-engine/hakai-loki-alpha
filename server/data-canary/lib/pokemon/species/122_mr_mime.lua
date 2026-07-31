return {
	id = 122,
	name = "Mr Mime",
	types = { "psychic", "fairy" },
	baseStats = {
		hp = 40,
		attack = 45,
		defense = 65,
		specialAttack = 100,
		specialDefense = 120,
		speed = 90,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 161,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 866, method = "level-up", level = 42 },
	evolutions = { { speciesId = 866, method = "level-up", level = 42 } },
	runtime = { placeholder = false, lookType = 3122, level = 20 },
}
