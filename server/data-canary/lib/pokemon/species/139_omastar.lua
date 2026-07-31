return {
	id = 139,
	name = "Omastar",
	types = { "rock", "water" },
	baseStats = {
		hp = 70,
		attack = 60,
		defense = 125,
		specialAttack = 115,
		specialDefense = 70,
		speed = 55,
	},
	gender = { male = 875, female = 125, genderless = 0 },
	catchRate = 45,
	baseExperience = 173,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3139, level = 40 },
}
