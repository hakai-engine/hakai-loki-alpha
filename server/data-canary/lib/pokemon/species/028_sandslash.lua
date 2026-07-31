return {
	id = 28,
	name = "Sandslash",
	types = { "ground" },
	baseStats = {
		hp = 75,
		attack = 100,
		defense = 110,
		specialAttack = 45,
		specialDefense = 55,
		speed = 65,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 90,
	baseExperience = 158,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3028, level = 40 },
}
