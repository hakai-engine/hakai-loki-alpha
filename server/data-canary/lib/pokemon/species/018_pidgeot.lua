return {
	id = 18,
	name = "Pidgeot",
	types = { "normal", "flying" },
	baseStats = {
		hp = 83,
		attack = 80,
		defense = 75,
		specialAttack = 70,
		specialDefense = 70,
		speed = 101,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 216,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3018, level = 40 },
}
