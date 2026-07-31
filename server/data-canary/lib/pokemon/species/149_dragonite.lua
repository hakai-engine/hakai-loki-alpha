return {
	id = 149,
	name = "Dragonite",
	types = { "dragon", "flying" },
	baseStats = {
		hp = 91,
		attack = 134,
		defense = 95,
		specialAttack = 100,
		specialDefense = 100,
		speed = 80,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 270,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3149, level = 50 },
}
