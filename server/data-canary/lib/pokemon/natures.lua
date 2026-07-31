PokemonNatures = {
	"hardy", "lonely", "brave", "adamant", "naughty",
	"bold", "docile", "relaxed", "impish", "lax",
	"timid", "hasty", "serious", "jolly", "naive",
	"modest", "mild", "quiet", "bashful", "rash",
	"calm", "gentle", "sassy", "careful", "quirky",
}

PokemonNatures.ids = {
	hardy=POKEMON_NATURE_HARDY or 1, lonely=POKEMON_NATURE_LONELY or 2,
	brave=POKEMON_NATURE_BRAVE or 3, adamant=POKEMON_NATURE_ADAMANT or 4,
	naughty=POKEMON_NATURE_NAUGHTY or 5, bold=POKEMON_NATURE_BOLD or 6,
	docile=POKEMON_NATURE_DOCILE or 7, relaxed=POKEMON_NATURE_RELAXED or 8,
	impish=POKEMON_NATURE_IMPISH or 9, lax=POKEMON_NATURE_LAX or 10,
	timid=POKEMON_NATURE_TIMID or 11, hasty=POKEMON_NATURE_HASTY or 12,
	serious=POKEMON_NATURE_SERIOUS or 13, jolly=POKEMON_NATURE_JOLLY or 14,
	naive=POKEMON_NATURE_NAIVE or 15, modest=POKEMON_NATURE_MODEST or 16,
	mild=POKEMON_NATURE_MILD or 17, quiet=POKEMON_NATURE_QUIET or 18,
	bashful=POKEMON_NATURE_BASHFUL or 19, rash=POKEMON_NATURE_RASH or 20,
	calm=POKEMON_NATURE_CALM or 21, gentle=POKEMON_NATURE_GENTLE or 22,
	sassy=POKEMON_NATURE_SASSY or 23, careful=POKEMON_NATURE_CAREFUL or 24,
	quirky=POKEMON_NATURE_QUIRKY or 25,
}

function PokemonNatures.id(nature)
	return PokemonNatures.ids[nature] or (POKEMON_NATURE_NONE or 0)
end

function PokemonNatures.random()
	return PokemonNatures[math.random(#PokemonNatures)]
end

function PokemonNatures.isValid(nature)
	for _, candidate in ipairs(PokemonNatures) do
		if candidate == nature then
			return true
		end
	end
	return false
end
