return {
	id = 30,
	name = "Nidorina",
	types = { "poison" },
	baseStats = {
		hp = 70,
		attack = 62,
		defense = 67,
		specialAttack = 55,
		specialDefense = 55,
		speed = 56,
	},
	gender = { male = 0, female = 1000, genderless = 0 },
	catchRate = 120,
	baseExperience = 128,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 31, method = "use-item", item = "moon-stone" },
	evolutions = { { speciesId = 31, method = "use-item", item = "moon-stone" } },
	runtime = { placeholder = false, lookType = 3030, level = 20 },
}
