PokemonEncounter = { active = {} }

local function rollGender(weights)
    local roll=math.random(1000)
    if roll<=weights.male then return PokemonConstants.GENDERS.MALE end
    if roll<=weights.male+weights.female then return PokemonConstants.GENDERS.FEMALE end
    return PokemonConstants.GENDERS.GENDERLESS
end

local function rollIvs()
    local ivs={}
    for _,stat in ipairs(PokemonConstants.STAT_KEYS) do
        ivs[stat] = PokemonRules.ivsEnabled
            and math.random(PokemonConstants.IV_MIN,PokemonConstants.IV_MAX)
            or 0
    end
    return ivs
end

function PokemonEncounter.create(speciesId,level,context)
    local species=assert(PokemonSpecies.get(speciesId),"unknown Pokemon species "..tostring(speciesId))
    local profile = PokemonCombatConfig.encounterClassProfile(species.classification, context)
    return {
        schemaVersion=PokemonConstants.SCHEMA_VERSION,
        speciesId=species.id,
        gender=PokemonRules.genderEnabled and rollGender(species.gender) or PokemonConstants.GENDERS.GENDERLESS,
        nature=PokemonRules.natureEnabled and PokemonNatures.random() or "hardy",
		level=PokemonCombatConfig.effectiveLevel(profile.level or level or 1),
        ivs=rollIvs(),
        classification=species.classification,
        runtimeCombatModifiers={
            healthMultiplier=profile.healthMultiplier or 1.0,
            damageMultiplier=profile.damageMultiplier or 1.0,
        },
    }
end

function PokemonEncounter.applyRuntimeCombatProfile(monster, encounter)
    local species=assert(PokemonSpecies.get(encounter.speciesId))
	local level = PokemonCombatConfig.effectiveLevel(encounter.level)
    local stats=PokemonStats.calculate(species,level,encounter.ivs,encounter.nature,encounter.gender)
    local type1=PokemonTypes.id(assert(species.types[1],"Pokemon species requires a primary type"))
    local type2=species.types[2] and PokemonTypes.id(species.types[2]) or 0
    local modifiers = encounter.runtimeCombatModifiers or {}
    local healthMultiplier = math.max(0, tonumber(modifiers.healthMultiplier) or 1.0)
    local damageMultiplier = math.max(0, tonumber(modifiers.damageMultiplier) or 1.0)
    stats.hp = math.max(1, math.ceil(stats.hp * healthMultiplier))
    assert(monster:setPokemonCombatProfile(
		level,
        type1,
        type2,
        stats.attack,
        stats.defense,
        stats.specialAttack,
        stats.specialDefense,
        stats.speed,
        PokemonCombatConfig.genderDamageMultiplier(encounter.gender) * damageMultiplier
    ), "failed to attach native Pokemon combat profile")
    return stats
end

function PokemonEncounter.applyDisplayName(monster, pokemon)
    if not monster or type(monster.setName) ~= "function" or type(pokemon) ~= "table" then
        return false
    end

    local species = PokemonSpecies.get(pokemon.speciesId)
    local level = tonumber(pokemon.level)
    if not species or not level then
        return false
    end

    level = PokemonCombatConfig.effectiveLevel(level)
    local displayName = string.format("%s [Lv. %d]", species.name, level)
    local description = string.format("a %s [lv. %d]", string.lower(species.name), level)
    return monster:setName(displayName, description) == true
end

function PokemonEncounter.attach(monster,speciesId,level)
    local encounter=PokemonEncounter.create(speciesId,level,"wild")
    local maximumHp=PokemonEncounter.applyRuntimeCombatProfile(monster,encounter).hp
    encounter.runtimeCreatureId=monster:getId()
    PokemonEncounter.active[encounter.runtimeCreatureId]=encounter
    monster:setMaxHealth(maximumHp)
    local healthDifference=maximumHp-monster:getHealth()
    if healthDifference~=0 then monster:addHealth(healthDifference) end
    return encounter
end
function PokemonEncounter.get(monsterOrId)
    local id=type(monsterOrId)=="number" and monsterOrId or monsterOrId:getId(); return PokemonEncounter.active[id]
end
function PokemonEncounter.release(monsterOrId)
    local id=type(monsterOrId)=="number" and monsterOrId or monsterOrId:getId(); local encounter=PokemonEncounter.active[id]; PokemonEncounter.active[id]=nil; return encounter
end
