return {
	id = 133,
	name = "Eevee",
	types = { "normal" },
	baseStats = {
		hp = 55,
		attack = 55,
		defense = 50,
		specialAttack = 45,
		specialDefense = 65,
		speed = 55,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 65,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 134, method = "use-item", item = "water-stone" },
	evolutions = { { speciesId = 134, method = "use-item", item = "water-stone" }, { speciesId = 135, method = "use-item", item = "thunder-stone" }, { speciesId = 136, method = "use-item", item = "fire-stone" }, { speciesId = 196, method = "level-up" }, { speciesId = 197, method = "level-up" }, { speciesId = 470, method = "level-up" }, { speciesId = 471, method = "level-up" }, { speciesId = 700, method = "level-up" } },
	runtime = { placeholder = false, lookType = 3133, level = 5 },
}
