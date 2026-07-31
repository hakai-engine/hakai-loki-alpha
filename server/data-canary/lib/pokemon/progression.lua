-- Persistent Pokemon progression. Experience is cumulative and follows the
-- classic medium-fast curve: total XP required for level N is N^3. The cap is
-- deliberately the same authoritative 1..1000 level range used by combat.
PokemonProgression = {
    rate = (PokemonCombatConfig.progression and PokemonCombatConfig.progression.experienceRate) or 1.0,
}

local function integer(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

function PokemonProgression.experienceForLevel(level)
    level = PokemonCombatConfig.effectiveLevel(level)
    return level * level * level
end

function PokemonProgression.maximumExperience()
    return PokemonProgression.experienceForLevel(PokemonCombatConfig.level.maximum)
end

function PokemonProgression.levelForExperience(experience)
    experience = math.min(integer(experience), PokemonProgression.maximumExperience())
    local level = 1
    while level < PokemonCombatConfig.level.maximum
        and experience >= PokemonProgression.experienceForLevel(level + 1)
    do
        level = level + 1
    end
    return level
end

function PokemonProgression.normalizeExperience(instance)
    local minimum = PokemonProgression.experienceForLevel(instance.level)
    local normalized = math.max(minimum, integer(instance.experience))
    normalized = math.min(normalized, PokemonProgression.maximumExperience())
    local changed = normalized ~= instance.experience
    instance.experience = normalized
    return changed
end

function PokemonProgression.applyExperience(instance, amount)
    assert(type(instance) == "table", "Pokemon experience requires an instance")
    amount = integer(amount)
    PokemonProgression.normalizeExperience(instance)
    local previous = {
        level = instance.level,
        experience = integer(instance.experience),
        currentHp = instance.currentHp,
        maxHp = instance.maxHp,
        state = instance.state,
    }
    local progressed = {}
    for key, value in pairs(instance) do
        progressed[key] = value
    end
    progressed.experience = math.min(previous.experience + amount, PokemonProgression.maximumExperience())
    progressed.level = PokemonProgression.levelForExperience(progressed.experience)
    PokemonRepository.normalizeVitals(progressed)
    return progressed, {
        gained = progressed.experience - previous.experience,
        previousLevel = previous.level,
        leveledUp = progressed.level > previous.level,
    }
end

-- The native death pipeline can resolve mostDamageKiller to the summon master
-- (the Trainer), while lastHitKiller can still be the Monster. Resolve both
-- forms to the *active summon record*, never to a species or a Team slot.
-- This keeps the persisted instance authoritative for XP attribution.
function PokemonProgression.participantFor(creature)
    if not creature or not PokemonSummon then
        return nil
    end

    local active = PokemonSummon.getByCreature(creature:getId())
    if active then
        return active
    end

    -- Canary promotes mostDamageKiller from a summon to its Player master
    -- before onDeath. The Trainer itself never receives Pokemon XP; this only
    -- retrieves the currently projected instance that performed the battle.
    if creature.isPlayer and creature:isPlayer() then
        return PokemonSummon.get(creature)
    end

    return nil
end

local function publish(player, instance, message)
    if PokemonCaptureBag then
        PokemonCaptureBag.updateInstance(instance)
    end
    if PokemonTeam then
        local session = PokemonTeam.ensureLoaded(player)
        session.revision = session.revision + 1
    end
    if PokemonRosterProtocol then
        PokemonRosterProtocol.snapshot(player, false, message, true)
    end
end

function PokemonProgression.gain(player, instanceId, amount)
    if not player or not player:isPlayer() then
        return nil, "Pokemon experience requires an online player"
    end
    amount = integer(amount)
    if amount <= 0 then
        return nil, "no Pokemon experience to award"
    end

    local previous, reason = PokemonRepository.load(tostring(instanceId), player:getGuid())
    if not previous then
        return nil, reason
    end
    if previous.state ~= "ready" then
        return nil, "fainted Pokemon cannot receive experience"
    end

    -- The active projection is the current HP authority while it is outside.
    local active = PokemonSummon and PokemonSummon.get(player)
    if active and tostring(active.instanceId) == tostring(previous.instanceId) then
        local monster = Monster(active.creatureId)
        if monster then
            previous.maxHp = math.max(monster:getMaxHealth(), 1)
            previous.currentHp = math.max(0, math.min(monster:getHealth(), previous.maxHp))
            previous.state = previous.currentHp > 0 and "ready" or "fainted"
        end
    end

    local progressed, details = PokemonProgression.applyExperience(previous, amount)
    local persisted, persistReason = PokemonRepository.persistProgression(previous, progressed)
    if not persisted then
        return nil, persistReason
    end

    local evolutionMessage
    local refreshedByEvolution = false
    if details.leveledUp and PokemonEvolution then
        local evolved, evolutionReason = PokemonEvolution.evolveStoredByLevel(player, persisted.instanceId, {
            allowActive = true,
            suppressSnapshot = true,
        })
        if evolved then
            persisted = evolved
            refreshedByEvolution = true
            evolutionMessage = string.format(" %s evolved into %s.", PokemonSpecies.get(progressed.speciesId).name, PokemonSpecies.get(evolved.speciesId).name)
        elseif evolutionReason ~= "no eligible evolution route" then
            logger.error("[PokemonProgression] Could not evolve instance {} after level {}: {}", persisted.instanceId, persisted.level, evolutionReason)
        end
    end

    if PokemonSummon and not refreshedByEvolution then
        PokemonSummon.refreshActiveInstance(player, persisted, previous.speciesId)
    end
    local species = PokemonSpecies.get(persisted.speciesId)
    local message = string.format("%s gained %d Pokemon XP", species.name, details.gained)
    if details.leveledUp then
        message = message .. string.format(" and reached level %d!", persisted.level)
    else
        message = message .. "."
    end
    message = message .. (evolutionMessage or "")
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)

    -- Replace Canary's native summon-XP float with the authoritative gain of
    -- this persisted Pokemon instance. The numeric payload is what Thor draws
    -- above the summon; it is deliberately not the Trainer's XP.
    local activeProjection = PokemonSummon and PokemonSummon.get(player)
    if activeProjection and tostring(activeProjection.instanceId) == tostring(persisted.instanceId) then
        local monster = Monster(activeProjection.creatureId)
        if monster then
            player:sendTextMessage(
                MESSAGE_EXPERIENCE,
                string.format("%s gained %d Pokemon XP.", species.name, details.gained),
                monster:getPosition(),
                details.gained,
                TEXTCOLOR_WHITE_EXP
            )
        end
    end
    publish(player, persisted, message)
    return persisted, details
end

function PokemonProgression.awardForDefeat(defeated, killer, mostDamageKiller)
    if not defeated or defeated:getMaster() then
        return false
    end
    local encounter = PokemonEncounter.get(defeated)
    if not encounter then
        return false
    end
    -- Last hit receives priority. The most-damage participant is a safe
    -- fallback for fields/conditions that do not preserve the summon as killer.
    local active = PokemonProgression.participantFor(killer)
        or PokemonProgression.participantFor(mostDamageKiller)
    if not active then
        return false
    end
    local player = active.playerId and Player(active.playerId) or nil
    if not player or not player:isPlayer() then
        return false
    end
    local species = PokemonSpecies.get(encounter.speciesId)
    local amount = integer((tonumber(species.baseExperience) or 0) * PokemonProgression.rate)
    if amount <= 0 then
        return false
    end
    local persisted, reason = PokemonProgression.gain(player, active.instanceId, amount)
    if not persisted then
        logger.error("[PokemonProgression] Failed to award {} XP from {} to instance {}: {}", amount, species.name, active.instanceId, reason)
        return false
    end
    return true
end
