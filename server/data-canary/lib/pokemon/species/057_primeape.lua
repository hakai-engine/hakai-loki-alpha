return {
	id = 57,
	name = "Primeape",
	types = { "fighting" },
	baseStats = {
		hp = 65,
		attack = 105,
		defense = 60,
		specialAttack = 60,
		specialDefense = 70,
		speed = 95,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 75,
	baseExperience = 159,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 979, method = "use-move" },
	evolutions = { { speciesId = 979, method = "use-move" } },
	runtime = { placeholder = false, lookType = 3057, level = 20 },
}
