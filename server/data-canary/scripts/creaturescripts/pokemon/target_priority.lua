local pokemonTargetPriority = CreatureEvent("PokemonTargetPriority")

function pokemonTargetPriority.onThink(creature, interval)
    if PokemonTargetPolicy then
        PokemonTargetPolicy.enforce(creature)
    end
    return true
end

pokemonTargetPriority:register()
