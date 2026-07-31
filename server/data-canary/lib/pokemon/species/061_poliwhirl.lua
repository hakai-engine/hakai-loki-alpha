return {
	id = 61,
	name = "Poliwhirl",
	types = { "water" },
	baseStats = {
		hp = 65,
		attack = 65,
		defense = 65,
		specialAttack = 50,
		specialDefense = 50,
		speed = 90,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 120,
	baseExperience = 135,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 62, method = "use-item", item = "water-stone" },
	evolutions = { { speciesId = 62, method = "use-item", item = "water-stone" }, { speciesId = 186, method = "trade", item = "kings-rock" } },
	runtime = { placeholder = false, lookType = 3061, level = 20 },
}
