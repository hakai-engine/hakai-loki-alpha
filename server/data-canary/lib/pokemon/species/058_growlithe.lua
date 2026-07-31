return {
	id = 58,
	name = "Growlithe",
	types = { "fire" },
	baseStats = {
		hp = 55,
		attack = 70,
		defense = 45,
		specialAttack = 70,
		specialDefense = 50,
		speed = 60,
	},
	gender = { male = 750, female = 250, genderless = 0 },
	catchRate = 190,
	baseExperience = 70,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 59, method = "use-item", item = "fire-stone" },
	evolutions = { { speciesId = 59, method = "use-item", item = "fire-stone" } },
	runtime = { placeholder = false, lookType = 3058, level = 5 },
}
