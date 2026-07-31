local pokemonCorpseIdentity = CreatureEvent("PokemonCorpseIdentity")

local function eligibleTrainer(participant)
    if not participant then return nil end
    local player = participant:isPlayer() and participant or participant:getMaster()
    if not player or not PokemonCapture.isEligibleTrainer(player) then return nil end
    return player
end

function pokemonCorpseIdentity.onDeath(creature, corpse, killer, mostDamageKiller)
    if creature:getMaster() then return true end
    local encounter = PokemonEncounter.get(creature)
    if not encounter then
        logger.error("[PokemonCorpseIdentity] Missing encounter for {}", creature:getName())
        return true
    end
    local owner = eligibleTrainer(killer) or eligibleTrainer(mostDamageKiller)
    if not owner then
        logger.debug("[PokemonCorpseIdentity] {} died without an eligible Trainer capture owner.", creature:getName())
        return true
    end
    local ok, reason = PokemonCapture.markCorpse(corpse, encounter, owner:getGuid())
    if not ok then logger.error("[PokemonCorpseIdentity] Could not mark {} corpse: {}", creature:getName(), reason) end
    return true
end

pokemonCorpseIdentity:register()


