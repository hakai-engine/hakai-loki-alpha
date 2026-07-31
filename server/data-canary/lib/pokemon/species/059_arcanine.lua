return {
	id = 59,
	name = "Arcanine",
	types = { "fire" },
	baseStats = {
		hp = 90,
		attack = 110,
		defense = 80,
		specialAttack = 100,
		specialDefense = 80,
		speed = 95,
	},
	gender = { male = 750, female = 250, genderless = 0 },
	catchRate = 75,
	baseExperience = 194,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3059, level = 40 },
}
