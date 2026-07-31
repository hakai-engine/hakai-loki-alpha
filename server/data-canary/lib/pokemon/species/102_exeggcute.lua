return {
	id = 102,
	name = "Exeggcute",
	types = { "grass", "psychic" },
	baseStats = {
		hp = 60,
		attack = 40,
		defense = 80,
		specialAttack = 60,
		specialDefense = 45,
		speed = 40,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 90,
	baseExperience = 65,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 103, method = "use-item", item = "leaf-stone" },
	evolutions = { { speciesId = 103, method = "use-item", item = "leaf-stone" } },
	runtime = { placeholder = false, lookType = 3102, level = 5 },
}
