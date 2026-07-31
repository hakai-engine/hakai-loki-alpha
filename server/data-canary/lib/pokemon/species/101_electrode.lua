return {
	id = 101,
	name = "Electrode",
	types = { "electric" },
	baseStats = {
		hp = 60,
		attack = 50,
		defense = 70,
		specialAttack = 80,
		specialDefense = 80,
		speed = 150,
	},
	gender = { male = 0, female = 0, genderless = 1000 },
	catchRate = 60,
	baseExperience = 172,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3101, level = 40 },
}
