return {
	id = 44,
	name = "Gloom",
	types = { "grass", "poison" },
	baseStats = {
		hp = 60,
		attack = 65,
		defense = 70,
		specialAttack = 85,
		specialDefense = 75,
		speed = 40,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 120,
	baseExperience = 138,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 45, method = "use-item", item = "leaf-stone" },
	evolutions = { { speciesId = 45, method = "use-item", item = "leaf-stone" }, { speciesId = 182, method = "use-item", item = "sun-stone" } },
	runtime = { placeholder = false, lookType = 3044, level = 20 },
}
