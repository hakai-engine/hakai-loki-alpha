return {
	id = 105,
	name = "Marowak",
	types = { "ground" },
	baseStats = {
		hp = 60,
		attack = 80,
		defense = 110,
		specialAttack = 50,
		specialDefense = 80,
		speed = 45,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 75,
	baseExperience = 149,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3105, level = 40 },
}
