return {
	id = 70,
	name = "Weepinbell",
	types = { "grass", "poison" },
	baseStats = {
		hp = 65,
		attack = 90,
		defense = 50,
		specialAttack = 85,
		specialDefense = 45,
		speed = 55,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 120,
	baseExperience = 137,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 71, method = "use-item", item = "leaf-stone" },
	evolutions = { { speciesId = 71, method = "use-item", item = "leaf-stone" } },
	runtime = { placeholder = false, lookType = 3070, level = 20 },
}
