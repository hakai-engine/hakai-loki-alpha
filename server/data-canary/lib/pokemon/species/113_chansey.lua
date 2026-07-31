return {
	id = 113,
	name = "Chansey",
	types = { "normal" },
	baseStats = {
		hp = 250,
		attack = 5,
		defense = 5,
		specialAttack = 35,
		specialDefense = 105,
		speed = 50,
	},
	gender = { male = 0, female = 1000, genderless = 0 },
	catchRate = 30,
	baseExperience = 395,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 242, method = "level-up" },
	evolutions = { { speciesId = 242, method = "level-up" } },
	runtime = { placeholder = false, lookType = 3113, level = 20 },
}
