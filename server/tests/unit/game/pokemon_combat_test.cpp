#include "creatures/combat/combat.hpp"

namespace {
PokemonCombatProfile profile(
	uint16_t level,
	PokemonType_t type1,
	PokemonType_t type2 = PokemonType_t::NONE,
	uint32_t attack = 100,
	uint32_t defense = 100,
	uint32_t specialAttack = 100,
	uint32_t specialDefense = 100,
	double genderDamageMultiplier = 1.0
) {
	PokemonCombatProfile result;
	result.valid = true;
	result.level = level;
	result.types = { type1, type2 };
	result.attack = attack;
	result.defense = defense;
	result.specialAttack = specialAttack;
	result.specialDefense = specialDefense;
	result.genderDamageMultiplier = genderDamageMultiplier;
	return result;
}

constexpr std::array<std::array<uint16_t, POKEMON_TYPE_COUNT>, POKEMON_TYPE_COUNT> modernTypeChartPercent = {{
	{ 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 50, 0, 100, 100, 50, 100 },
	{ 100, 50, 50, 100, 200, 200, 100, 100, 100, 100, 100, 200, 50, 100, 50, 100, 200, 100 },
	{ 100, 200, 50, 100, 50, 100, 100, 100, 200, 100, 100, 100, 200, 100, 50, 100, 100, 100 },
	{ 100, 100, 200, 50, 50, 100, 100, 100, 0, 200, 100, 100, 100, 100, 50, 100, 100, 100 },
	{ 100, 50, 200, 100, 50, 100, 100, 50, 200, 50, 100, 50, 200, 100, 50, 100, 50, 100 },
	{ 100, 50, 50, 100, 200, 50, 100, 100, 200, 200, 100, 100, 200, 100, 200, 100, 50, 100 },
	{ 200, 100, 100, 100, 100, 200, 100, 50, 100, 50, 50, 50, 200, 0, 100, 200, 200, 50 },
	{ 100, 100, 100, 100, 200, 100, 100, 50, 50, 100, 100, 100, 50, 50, 100, 100, 0, 200 },
	{ 100, 200, 100, 200, 50, 100, 100, 200, 100, 0, 100, 50, 200, 100, 100, 100, 200, 100 },
	{ 100, 100, 100, 50, 200, 100, 200, 100, 100, 100, 100, 200, 50, 100, 100, 100, 50, 100 },
	{ 100, 100, 100, 100, 100, 100, 200, 200, 100, 100, 50, 100, 100, 100, 100, 0, 50, 100 },
	{ 100, 50, 100, 100, 200, 100, 50, 50, 100, 50, 200, 100, 100, 50, 100, 200, 50, 50 },
	{ 100, 200, 100, 100, 100, 200, 50, 100, 50, 200, 100, 200, 100, 100, 100, 100, 50, 100 },
	{ 0, 100, 100, 100, 100, 100, 100, 100, 100, 100, 200, 100, 100, 200, 100, 50, 100, 100 },
	{ 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 200, 100, 50, 0 },
	{ 100, 100, 100, 100, 100, 100, 50, 100, 100, 100, 200, 200, 100, 200, 100, 50, 100, 50 },
	{ 100, 50, 50, 50, 100, 200, 100, 100, 100, 100, 100, 100, 200, 100, 100, 100, 50, 200 },
	{ 100, 50, 100, 100, 100, 100, 200, 50, 100, 100, 100, 100, 100, 100, 200, 200, 50, 100 },
}};
}

TEST(PokemonCombatTest, MatchesModernGoldenChartForAll324TypePairs) {
	for (uint8_t attack = 1; attack <= POKEMON_TYPE_COUNT; ++attack) {
		for (uint8_t defense = 1; defense <= POKEMON_TYPE_COUNT; ++defense) {
			const auto actual = Combat::getPokemonTypeEffectiveness(
				static_cast<PokemonType_t>(attack),
				{ static_cast<PokemonType_t>(defense), PokemonType_t::NONE }
			);
			const auto expected = static_cast<double>(modernTypeChartPercent[attack - 1][defense - 1]) / 100.0;
			EXPECT_DOUBLE_EQ(actual, expected)
				<< "attack type " << static_cast<int>(attack)
				<< ", defense type " << static_cast<int>(defense);
		}
	}
}

TEST(PokemonCombatTest, AppliesBothDefenderTypesIncludingImmunity) {
	const std::array charizardTypes { PokemonType_t::FIRE, PokemonType_t::FLYING };
	EXPECT_DOUBLE_EQ(
		Combat::getPokemonTypeEffectiveness(PokemonType_t::GROUND, charizardTypes),
		0.0
	);
	EXPECT_DOUBLE_EQ(
		Combat::getPokemonTypeEffectiveness(PokemonType_t::ROCK, charizardTypes),
		4.0
	);
}

TEST(PokemonCombatTest, UsesPhysicalAttackAndDefenseWithStabAndGenderLast) {
	const auto attacker = profile(
		50,
		PokemonType_t::GROUND,
		PokemonType_t::NONE,
		100,
		100,
		100,
		100,
		1.10
	);
	const auto target = profile(50, PokemonType_t::FIRE);

	EXPECT_EQ(
		Combat::calculatePokemonDamage(
			attacker,
			target,
			PokemonType_t::GROUND,
			PokemonMoveCategory_t::PHYSICAL,
			100,
			100,
			false
		),
		151
	);
}

TEST(PokemonCombatTest, UsesSpecialAttackAndSpecialDefense) {
	const auto attacker = profile(
		50,
		PokemonType_t::WATER,
		PokemonType_t::NONE,
		10,
		100,
		200,
		100
	);
	const auto target = profile(
		50,
		PokemonType_t::FIRE,
		PokemonType_t::NONE,
		100,
		100,
		100,
		50
	);

	EXPECT_EQ(
		Combat::calculatePokemonDamage(
			attacker,
			target,
			PokemonType_t::WATER,
			PokemonMoveCategory_t::SPECIAL,
			100,
			100,
			false
		),
		534
	);
}

TEST(PokemonCombatTest, TreatsZeroDefensesAsSafeDenominatorOne) {
	const auto attacker = profile(50, PokemonType_t::FIRE);
	const auto target = profile(
		50,
		PokemonType_t::NORMAL,
		PokemonType_t::NONE,
		100,
		0,
		100,
		0
	);

	EXPECT_EQ(
		Combat::calculatePokemonDamage(
			attacker,
			target,
			PokemonType_t::NORMAL,
			PokemonMoveCategory_t::PHYSICAL,
			100,
			100,
			false
		),
		4402
	);
	EXPECT_EQ(
		Combat::calculatePokemonDamage(
			attacker,
			target,
			PokemonType_t::NORMAL,
			PokemonMoveCategory_t::SPECIAL,
			100,
			100,
			false
		),
		4402
	);
}

TEST(PokemonCombatTest, ReturnsZeroForStatusAndTypeImmunity) {
	const auto attacker = profile(50, PokemonType_t::GROUND);
	const auto charizard = profile(50, PokemonType_t::FIRE, PokemonType_t::FLYING);

	EXPECT_EQ(
		Combat::calculatePokemonDamage(
			attacker,
			charizard,
			PokemonType_t::GROUND,
			PokemonMoveCategory_t::PHYSICAL,
			100,
			100,
			false
		),
		0
	);
	EXPECT_EQ(
		Combat::calculatePokemonDamage(
			attacker,
			charizard,
			PokemonType_t::GROUND,
			PokemonMoveCategory_t::STATUS,
			100,
			100,
			false
		),
		0
	);
}
