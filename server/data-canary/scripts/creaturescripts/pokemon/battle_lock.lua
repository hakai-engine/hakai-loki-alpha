local pokemonBattleLock = CreatureEvent("PokemonBattleLock")

function pokemonBattleLock.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
    -- Canary reports combat damage as a negative value. Healing must not lock
    -- roster management, so ignore events without actual incoming damage.
    if (tonumber(primaryDamage) or 0) < 0 or (tonumber(secondaryDamage) or 0) < 0 then
        PokemonBattleLock.markBySummonCreature(creature)
        PokemonBattleLock.markBySummonCreature(attacker)
    end
    return primaryDamage, primaryType, secondaryDamage, secondaryType
end

pokemonBattleLock:register()
