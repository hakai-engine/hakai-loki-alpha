return {
	id = 22,
	name = "Fearow",
	types = { "normal", "flying" },
	baseStats = {
		hp = 65,
		attack = 90,
		defense = 65,
		specialAttack = 61,
		specialDefense = 61,
		speed = 100,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 90,
	baseExperience = 155,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3022, level = 40 },
}
