return {
	id = 12,
	name = "Butterfree",
	types = { "bug", "flying" },
	baseStats = {
		hp = 60,
		attack = 45,
		defense = 50,
		specialAttack = 90,
		specialDefense = 80,
		speed = 70,
	},
	gender = { male = 500, female = 500, genderless = 0 },
	catchRate = 45,
	baseExperience = 178,
	-- evolution keeps the first route for legacy consumers. New code must use evolutions.
	evolution = nil,
	evolutions = {},
	runtime = { placeholder = false, lookType = 3012, level = 40 },
}
