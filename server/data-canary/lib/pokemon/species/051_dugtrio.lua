return {
	id = 51,
	name = "Dugtrio",
	types = { "ground" },
	baseStats = {
		hp = 35,
		attack = 100,
		defense = 50,
		specialAttack = 50,
		specialDefense = 70,
		speed = 120,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 50,
	baseExperience = 149,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3051, level = 40 },
}
