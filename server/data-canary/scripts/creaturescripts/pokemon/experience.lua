local pokemonExperience = CreatureEvent("PokemonExperience")

function pokemonExperience.onDeath(creature, corpse, killer, mostDamageKiller)
    PokemonProgression.awardForDefeat(creature, killer, mostDamageKiller)
    return true
end

pokemonExperience:register()
