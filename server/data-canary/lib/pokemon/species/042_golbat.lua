return {
	id = 42,
	name = "Golbat",
	types = { "poison", "flying" },
	baseStats = {
		hp = 75,
		attack = 80,
		defense = 70,
		specialAttack = 65,
		specialDefense = 75,
		speed = 90,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 90,
	baseExperience = 159,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = { speciesId = 169, method = "level-up" },
	evolutions = { { speciesId = 169, method = "level-up" } },
	runtime = { placeholder = false, lookType = 3042, level = 20 },
}
