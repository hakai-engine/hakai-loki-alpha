return {
	id = 90,
	name = "Shellder",
	types = { "water" },
	baseStats = {
		hp = 30,
		attack = 65,
		defense = 100,
		specialAttack = 45,
		specialDefense = 25,
		speed = 40,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 190,
	baseExperience = 61,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 91, method = "use-item", item = "water-stone" },
	evolutions = { { speciesId = 91, method = "use-item", item = "water-stone" } },
	runtime = { placeholder = false, lookType = 3090, level = 5 },
}
