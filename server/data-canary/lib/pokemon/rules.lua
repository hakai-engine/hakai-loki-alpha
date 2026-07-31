PokemonRules = {
    -- IVs remain part of the persistent encounter identity, but Alpha combat
    -- calibration intentionally uses species, level, nature and gender only.
    ivsAffectStats = false,
    naturesAffectStats = true,
    genderAffectsDamage = true,
    genderAffectsHp = true,
    speedAffectsBasicAttack = true,
    criticalHitsEnabled = true,
    trainerLevelAffectsPokemon = true,
    boostAffectsPokemon = true,
    gendersEnabled = true,
    trainerCombatEnabled = false,
    showMoveNames = true,
    -- Temporary runtime aid for the capture vertical-slice tests.
    -- Set to nil to restore the native species/ball formula.
    captureTestMinimumChance = 0.95,
    -- A valid attempt always consumes the Poke Ball. In single_attempt the
    -- corpse is finalized on either outcome; retry_on_break returns a failed
    -- attempt to READY so another Ball may be used.
    captureCorpsePolicy = "single_attempt",
}

local function readPokemonFeatureFlag(keyName, defaultValue)
    if type(configManager) ~= "table" or type(configKeys) ~= "table" or configKeys[keyName] == nil then
        return defaultValue
    end

    local ok, value = pcall(configManager.getBoolean, configKeys[keyName])
    if not ok or type(value) ~= "boolean" then
        return defaultValue
    end
    return value
end

PokemonRules.ivsEnabled = readPokemonFeatureFlag("POKEMON_IVS_ENABLED", true)
PokemonRules.genderEnabled = readPokemonFeatureFlag("POKEMON_GENDER_ENABLED", true)
PokemonRules.natureEnabled = readPokemonFeatureFlag("POKEMON_NATURE_ENABLED", true)
PokemonRules.gendersEnabled = PokemonRules.genderEnabled

PokemonRules.CAPTURE_CORPSE_POLICIES = {
    SINGLE_ATTEMPT = "single_attempt",
    RETRY_ON_BREAK = "retry_on_break",
}

function PokemonRules.isCaptureCorpsePolicy(value)
    return value == PokemonRules.CAPTURE_CORPSE_POLICIES.SINGLE_ATTEMPT
        or value == PokemonRules.CAPTURE_CORPSE_POLICIES.RETRY_ON_BREAK
end

function PokemonRules.setCaptureCorpsePolicy(policy)
    assert(PokemonRules.isCaptureCorpsePolicy(policy), "unknown capture corpse policy " .. tostring(policy))
    PokemonRules.captureCorpsePolicy = policy
end

function PokemonRules.set(name, enabled)
    assert(PokemonRules[name] ~= nil, "unknown Pokemon rule " .. tostring(name))
    PokemonRules[name] = enabled == true
end
