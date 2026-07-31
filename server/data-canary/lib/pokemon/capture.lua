PokemonCapture = {
    CORPSE_STATE_READY = "ready",
    CORPSE_STATE_RESOLVING = "resolving",
    -- Effect 250 has 60 phases at 50 ms each.
    SUCCESS_ANIMATION_MS = 3000,
}

local ATTR = {
    state = "hakai.capture.state",
    ownerGuid = "hakai.capture.ownerGuid",
    speciesId = "hakai.pokemon.speciesId",
    gender = "hakai.pokemon.gender",
    level = "hakai.pokemon.level",
    nature = "hakai.pokemon.nature",
    ivHp = "hakai.pokemon.iv.hp",
    ivAttack = "hakai.pokemon.iv.attack",
    ivDefense = "hakai.pokemon.iv.defense",
    ivSpecialAttack = "hakai.pokemon.iv.specialAttack",
    ivSpecialDefense = "hakai.pokemon.iv.specialDefense",
    ivSpeed = "hakai.pokemon.iv.speed",
}

function PokemonCapture.markCorpse(corpse, encounter, ownerGuid)
    if not corpse or not encounter then return false, "missing corpse or encounter" end
    ownerGuid = tonumber(ownerGuid)
    if not ownerGuid or ownerGuid <= 0 then return false, "missing eligible capture owner" end
    corpse:setCustomAttribute(ATTR.state, PokemonCapture.CORPSE_STATE_READY)
    corpse:setCustomAttribute(ATTR.ownerGuid, ownerGuid)
    corpse:setCustomAttribute(ATTR.speciesId, encounter.speciesId)
    corpse:setCustomAttribute(ATTR.gender, encounter.gender)
    corpse:setCustomAttribute(ATTR.level, encounter.level)
    corpse:setCustomAttribute(ATTR.nature, encounter.nature)
    corpse:setCustomAttribute(ATTR.ivHp, encounter.ivs.hp)
    corpse:setCustomAttribute(ATTR.ivAttack, encounter.ivs.attack)
    corpse:setCustomAttribute(ATTR.ivDefense, encounter.ivs.defense)
    corpse:setCustomAttribute(ATTR.ivSpecialAttack, encounter.ivs.specialAttack)
    corpse:setCustomAttribute(ATTR.ivSpecialDefense, encounter.ivs.specialDefense)
    corpse:setCustomAttribute(ATTR.ivSpeed, encounter.ivs.speed)
    return true
end

function PokemonCapture.readCorpse(corpse)
    if not corpse then return nil, "missing corpse" end
    local ownerGuid = tonumber(corpse:getCustomAttribute(ATTR.ownerGuid))
    if not ownerGuid or ownerGuid <= 0 then
        return nil, "corpse has no eligible capture owner"
    end
    local speciesId = tonumber(corpse:getCustomAttribute(ATTR.speciesId))
    if not speciesId or not PokemonSpecies.get(speciesId) then
        return nil, "corpse has no valid Pokemon encounter identity"
    end
    if corpse:getId() ~= PokemonCorpses.itemIdForSpecies(speciesId) then
        return nil, "corpse appearance does not match species"
    end
    local encounter = {
        schemaVersion = PokemonConstants.SCHEMA_VERSION,
        captureOwnerGuid = ownerGuid,
        speciesId = speciesId,
        gender = corpse:getCustomAttribute(ATTR.gender),
        level = tonumber(corpse:getCustomAttribute(ATTR.level)),
        nature = corpse:getCustomAttribute(ATTR.nature),
        ivs = {
            hp = tonumber(corpse:getCustomAttribute(ATTR.ivHp)),
            attack = tonumber(corpse:getCustomAttribute(ATTR.ivAttack)),
            defense = tonumber(corpse:getCustomAttribute(ATTR.ivDefense)),
            specialAttack = tonumber(corpse:getCustomAttribute(ATTR.ivSpecialAttack)),
            specialDefense = tonumber(corpse:getCustomAttribute(ATTR.ivSpecialDefense)),
            speed = tonumber(corpse:getCustomAttribute(ATTR.ivSpeed)),
        },
    }
    if not encounter.gender or not encounter.level or not PokemonNatures.isValid(encounter.nature) then return nil, "incomplete encounter identity" end
    for _, stat in ipairs(PokemonConstants.STAT_KEYS) do
        if encounter.ivs[stat] == nil then return nil, "incomplete encounter IVs" end
    end
    return encounter
end

function PokemonCapture.isEligibleTrainer(player)
    if not player or not player:isPlayer() then return false end
    local vocation = player:getVocation()
    return vocation and vocation:getId() == PokemonConstants.TRAINER_VOCATION_ID
end

function PokemonCapture.authorize(corpse, player)
    if not PokemonCapture.isEligibleTrainer(player) then
        return false, "only registered Trainers can capture Pokemon"
    end
    local ownerGuid = corpse and tonumber(corpse:getCustomAttribute(ATTR.ownerGuid)) or nil
    if not ownerGuid or ownerGuid <= 0 then
        return false, "corpse has no eligible capture owner"
    end
    if ownerGuid ~= player:getGuid() then
        return false, "corpse belongs to another Trainer"
    end
    return true
end

local function inspectCorpse(candidate)
    if not candidate or not PokemonCorpses.speciesIdForItem(candidate:getId()) then
        return nil, nil
    end

    local encounter, reason = PokemonCapture.readCorpse(candidate)
    if not encounter then
        return nil, reason
    end
    if candidate:getCustomAttribute(ATTR.state) ~= PokemonCapture.CORPSE_STATE_READY then
        return nil, "capture attempt already consumed"
    end
    return candidate, encounter
end

-- The client's target is only a hint. A living creature or another item can
-- occupy the top of the same tile and must not hide a capturable corpse.
function PokemonCapture.findReadyCorpse(position, preferredTarget)
    if not position or position.x == 0xFFFF then
        return nil, nil, "invalid capture position"
    end

    local corpse, encounter = inspectCorpse(preferredTarget)
    if corpse then
        return corpse, encounter
    end

    local tile = Tile(position)
    if not tile then
        return nil, nil, "capture tile does not exist"
    end

    local lastReason
    local items = tile:getItems() or {}
    for index = #items, 1, -1 do
        local candidate = items[index]
        local candidateCorpse, candidateEncounter = inspectCorpse(candidate)
        if candidateCorpse then
            return candidateCorpse, candidateEncounter
        end
        if PokemonCorpses.speciesIdForItem(candidate:getId()) then
            local _, reason = PokemonCapture.readCorpse(candidate)
            lastReason = reason or "capture attempt already consumed"
            if candidate:getCustomAttribute(ATTR.state) ~= PokemonCapture.CORPSE_STATE_READY then
                lastReason = "capture attempt already consumed"
            end
        end
    end

    return nil, nil, lastReason or "no capturable Pokemon corpse on tile"
end

function PokemonCapture.tryLockCorpse(corpse)
    if corpse:getCustomAttribute(ATTR.state) ~= PokemonCapture.CORPSE_STATE_READY then return false end
    corpse:setCustomAttribute(ATTR.state, PokemonCapture.CORPSE_STATE_RESOLVING)
    return true
end

function PokemonCapture.unlockCorpse(corpse)
    if corpse and corpse:getCustomAttribute(ATTR.state) == PokemonCapture.CORPSE_STATE_RESOLVING then
        corpse:setCustomAttribute(ATTR.state, PokemonCapture.CORPSE_STATE_READY)
        return true
    end
    return false
end

function PokemonCapture.shouldPreserveCorpseAfterFailure()
    local policy = PokemonRules.captureCorpsePolicy
    assert(PokemonRules.isCaptureCorpsePolicy(policy), "invalid capture corpse policy " .. tostring(policy))
    return policy == PokemonRules.CAPTURE_CORPSE_POLICIES.RETRY_ON_BREAK
end

function PokemonCapture.calculateChance(species, ballDefinition, additionalBonus)
    assert(species and ballDefinition, "capture chance requires species and ball")
    if ballDefinition.guaranteed then return 1 end
    local chance = PokemonBalls.calculateChance(species.catchRate / 255, ballDefinition.id, additionalBonus or 0)
    local testMinimum = tonumber(PokemonRules.captureTestMinimumChance)
    if testMinimum then
        chance = math.max(chance, math.max(0, math.min(testMinimum, 0.999999)))
    end
    return chance
end

function PokemonCapture.writeBallIdentity(item, instance, trainerName)
    item:setCustomAttribute("hakai.pokemon.instanceId", instance.instanceId)
    item:setCustomAttribute("hakai.pokemon.ownerGuid", instance.ownerGuid)
    item:setCustomAttribute("hakai.pokemon.originalTrainer", trainerName)
    item:setCustomAttribute("hakai.pokemon.speciesId", instance.speciesId)
    item:setCustomAttribute("hakai.pokemon.gender", instance.gender)
    item:setCustomAttribute("hakai.pokemon.nature", instance.nature)
    item:setCustomAttribute("hakai.pokemon.level", instance.level)
    for _, stat in ipairs(PokemonConstants.STAT_KEYS) do
        item:setCustomAttribute("hakai.pokemon.iv." .. stat, instance.ivs[stat])
    end
end

