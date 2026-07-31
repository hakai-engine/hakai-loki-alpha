PokemonCorpses = {
	FIRST_SPECIES_ID = 1,
	LAST_SPECIES_ID = 151,
	FIRST_ITEM_ID = 54269,
	LAST_ITEM_ID = 54419,
}

function PokemonCorpses.itemIdForSpecies(speciesId)
	assert(
		type(speciesId) == "number"
			and speciesId % 1 == 0
			and speciesId >= PokemonCorpses.FIRST_SPECIES_ID
			and speciesId <= PokemonCorpses.LAST_SPECIES_ID,
		"Pokemon corpse requires a Gen 1 species id (1..151)"
	)
	return PokemonCorpses.FIRST_ITEM_ID + speciesId - PokemonCorpses.FIRST_SPECIES_ID
end

function PokemonCorpses.speciesIdForItem(itemId)
	if type(itemId) ~= "number" or itemId < PokemonCorpses.FIRST_ITEM_ID or itemId > PokemonCorpses.LAST_ITEM_ID then
		return nil
	end
	return itemId - PokemonCorpses.FIRST_ITEM_ID + PokemonCorpses.FIRST_SPECIES_ID
end
