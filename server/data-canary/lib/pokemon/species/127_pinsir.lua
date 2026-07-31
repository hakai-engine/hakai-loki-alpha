return {
	id = 127,
	name = "Pinsir",
	types = { "bug" },
	baseStats = {
		hp = 65,
		attack = 125,
		defense = 100,
		specialAttack = 55,
		specialDefense = 70,
		speed = 85,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 175,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3127, level = 20 },
}
