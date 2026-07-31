return {
	id = 35,
	name = "Clefairy",
	types = { "fairy" },
	baseStats = {
		hp = 70,
		attack = 45,
		defense = 48,
		specialAttack = 60,
		specialDefense = 65,
		speed = 35,
	},
	gender = { male = 250, female = 750, genderless = 0 },
	catchRate = 150,
	baseExperience = 113,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 36, method = "use-item", item = "moon-stone" },
	evolutions = { { speciesId = 36, method = "use-item", item = "moon-stone" } },
	runtime = { placeholder = false, lookType = 3035, level = 20 },
}
