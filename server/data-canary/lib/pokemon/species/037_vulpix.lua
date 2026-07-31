return {
	id = 37,
	name = "Vulpix",
	types = { "fire" },
	baseStats = {
		hp = 38,
		attack = 41,
		defense = 40,
		specialAttack = 50,
		specialDefense = 65,
		speed = 65,
	},
	gender = { male = 250, female = 750, genderless = 0 },
	catchRate = 190,
	baseExperience = 60,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 38, method = "use-item", item = "fire-stone" },
	evolutions = { { speciesId = 38, method = "use-item", item = "fire-stone" } },
	runtime = { placeholder = false, lookType = 3037, level = 5 },
}
