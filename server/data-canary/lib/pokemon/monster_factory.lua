PokemonMonsterFactory = {}

local defaultLevels = { [1]=5,[2]=20,[3]=40,[4]=5,[5]=20,[6]=40,[7]=5,[8]=20,[9]=40 }

local moveCategoryId = {
    physical = POKEMON_MOVE_CATEGORY_PHYSICAL,
    special = POKEMON_MOVE_CATEGORY_SPECIAL,
    status = POKEMON_MOVE_CATEGORY_STATUS,
}

-- Deliberately use compact Canary effects first. Imported multi-tile Pokemon
-- appearances remain available as assets, but are not spatial authorities.
local typeEffect = {
    normal = CONST_ME_HITAREA,
    fire = CONST_ME_FIREAREA,
    water = CONST_ME_WATERSPLASH,
    grass = CONST_ME_GREEN_RINGS,
    electric = CONST_ME_ENERGYHIT,
    ice = CONST_ME_ICEATTACK,
    fighting = CONST_ME_EXPLOSIONHIT,
    poison = CONST_ME_HITBYPOISON,
    ground = CONST_ME_GROUNDSHAKER,
    flying = CONST_ME_SOUND_WHITE,
    psychic = CONST_ME_MAGIC_BLUE,
    bug = CONST_ME_MAGIC_GREEN,
    rock = CONST_ME_BLOCKHIT,
    ghost = CONST_ME_MORTAREA,
    dragon = CONST_ME_MAGIC_RED,
    dark = CONST_ME_SMALLCLOUDS,
    steel = CONST_ME_STUN,
    fairy = CONST_ME_HEARTS,
}

local moveEffect = {
    aurora_beam = CONST_ME_ICEATTACK,
}

-- Composed appearances are emitted once after the native combat succeeds.
-- They never define or repeat over the AreaCombat damage geometry.
local moveCastVisual = {
    earthquake = {
        north = 356,
        east = 356,
        south = 356,
        west = 356,
        width = 0,
        length = 0,
    },
    vine_whip = {
        north = 372,
        east = 375,
        south = 373,
        west = 374,
        width = 3,
        length = 3,
    },
    solar_beam = {
        north = 84,
        east = 83,
        south = 82,
        west = 81,
        width = 3,
        length = 6,
    },
}

local typeProjectile = {
    normal = CONST_ANI_LARGEROCK,
    fire = CONST_ANI_FIRE,
    water = CONST_ANI_SMALLICE,
    grass = CONST_ANI_GREENSTAR,
    electric = CONST_ANI_ENERGY,
    ice = CONST_ANI_ICE,
    fighting = CONST_ANI_LARGEROCK,
    poison = CONST_ANI_POISON,
    ground = CONST_ANI_SMALLSTONE,
    flying = CONST_ANI_WHIRLWINDSWORD,
    psychic = CONST_ANI_ENERGY,
    bug = CONST_ANI_GREENSTAR,
    rock = CONST_ANI_SMALLSTONE,
    ghost = CONST_ANI_DEATH,
    dragon = CONST_ANI_FIRE,
    dark = CONST_ANI_DEATH,
    steel = CONST_ANI_LARGEROCK,
    fairy = CONST_ANI_REDSTAR,
}

local directionalAreas = {
    vine_whip_wave = { length = 8, spread = 3 },
    forward3x6 = { length = 6, spread = 6 },
    forward3x6_taper = { length = 6, spread = 3 },
    forward3x5 = { length = 5, spread = 5 },
    forward3x3 = { length = 3, spread = 3 },
    forward3x1 = { length = 1, spread = 1 },
    forward1x6 = { length = 6, spread = 0 },
    forward1x5 = { length = 5, spread = 0 },
    forward1x2 = { length = 2, spread = 0 },
    dragon_breath = { length = 4, spread = 2 },
    heat_wave = { length = 5, spread = 3 },
}

local function radiusFromArea(area)
    local diameter = tonumber(tostring(area):match("(%d+)$"))
    return diameter and math.max(1, math.floor(diameter / 2)) or 1
end

local function nativeAttack(move)
    if move.category == "status" or (tonumber(move.power) or 0) <= 0 then
        return nil
    end

    local power = math.max(1, math.floor(tonumber(move.power) or 1))
    local attack = {
        name = "combat",
		pokemonMoveId = move.id,
        interval = math.max(100, math.floor(tonumber(move.cooldown) or 2000)),
        chance = math.max(0, math.min(100, math.floor(tonumber(move.chance) or 100))),
        type = COMBAT_NEUTRALDAMAGE,
        pokemonType = PokemonTypes.id(move.type),
        pokemonCategory = assert(moveCategoryId[move.category], "unknown Pokemon move category " .. tostring(move.category)),
        pokemonPower = power,
        minDamage = -power,
        maxDamage = -power,
        effect = moveEffect[move.id] or typeEffect[move.type] or CONST_ME_HITAREA,
        castText = move.name .. "!",
        target = move.targetMode ~= "self",
    }
    local castVisual = moveCastVisual[move.id]
    if castVisual then
        attack.effect = false
        attack.castVisual = castVisual
    end

    local directional = directionalAreas[move.area]
    if directional then
        attack.length = directional.length
        attack.spread = directional.spread
        attack.range = math.max(1, math.floor(tonumber(move.range) or directional.length))
        attack.target = false
        return attack
    end

    if move.area then
        attack.radius = radiusFromArea(move.area)
        attack.range = math.max(1, math.floor(tonumber(move.range) or attack.radius))
        attack.target = move.areaOrigin == "target"
        return attack
    end

    attack.range = math.max(1, math.floor(tonumber(move.range) or 1))
    if attack.target and attack.range > 1 then
        attack.shootEffect = typeProjectile[move.type] or CONST_ANI_LARGEROCK
    end
    return attack
end

local function moveAttacks(species)
    local basic = assert(PokemonMoves.get("basic_attack"), "Pokemon basic attack is not registered")
    local attacks = {
        {
            name = "combat",
            interval = basic.cooldown,
            chance = basic.chance,
            range = 1,
            target = true,
            type = COMBAT_NEUTRALDAMAGE,
            pokemonType = PokemonTypes.id(basic.type),
            pokemonCategory = POKEMON_MOVE_CATEGORY_PHYSICAL,
            pokemonPower = 35,
            minDamage = -35,
            maxDamage = -35,
            effect = CONST_ME_HITAREA,
        },
    }
    for _, move in ipairs(PokemonMoves.forSpecies(species.id)) do
        local attack = nativeAttack(move)
        if attack then table.insert(attacks, attack) end
    end
    return attacks
end

local function placeholderMonster(species)
    local placeholder, runtime = PokemonConstants.PLACEHOLDER, species.runtime or {}
    local level = runtime.level or defaultLevels[species.id] or 5
    local zeroIvs = { hp=0,attack=0,defense=0,specialAttack=0,specialDefense=0,speed=0 }
    local stats = PokemonStats.calculate(species, level, zeroIvs, "hardy")
    return {
        description = "a " .. species.name:lower(), experience = species.baseExperience,
        outfit = { lookType=runtime.lookType or placeholder.lookType,lookHead=0,lookBody=0,lookLegs=0,lookFeet=0,lookAddons=0,lookMount=0 },
        health=stats.hp, maxHealth=stats.hp, race=placeholder.race,
        corpse=PokemonCorpses.itemIdForSpecies(species.id), speed=runtime.speed or math.max(80, stats.speed * 2),
        changeTarget={interval=4000,chance=10}, strategiesTarget={nearest=100},
        flags={summonable=true,attackable=true,hostile=true,convinceable=true,pushable=true,rewardBoss=false,illusionable=true,canPushItems=false,canPushCreatures=false,staticAttackChance=runtime.staticAttackChance or 90,targetDistance=runtime.targetDistance or 1,runHealth=0,healthHidden=false,isBlockable=false,canWalkOnEnergy=false,canWalkOnFire=false,canWalkOnPoison=false},
        light={level=0,color=0}, voices={interval=5000,chance=10}, loot={},
        attacks=moveAttacks(species), defenses={defense=stats.defense,armor=0,mitigation=0}, elements={},
        immunities={{type="paralyze",condition=false},{type="outfit",condition=false},{type="invisible",condition=false},{type="bleed",condition=false}},
        raceId=species.bestiary.raceId,
        Bestiary={
            class="Kanto",
            race=BESTY_RACE_KANTO,
            toKill=species.bestiary.toKill,
            FirstUnlock=species.bestiary.firstUnlock,
            SecondUnlock=species.bestiary.secondUnlock,
            CharmsPoints=species.bestiary.charmsPoints,
            Stars=species.bestiary.stars,
            Occurrence=species.bestiary.occurrence,
            Locations=species.bestiary.locations,
        },
    }, level
end

function PokemonMonsterFactory.register(speciesId)
    local species = assert(PokemonSpecies.get(speciesId), "cannot register unknown Pokemon species")
    local monster, level = placeholderMonster(species)
    local mType = Game.createMonsterType(species.name)
    mType.onSpawn = function(spawnedMonster)
        PokemonEncounter.attach(spawnedMonster, species.id, level)
        spawnedMonster:registerEvent("PokemonCorpseIdentity")
        spawnedMonster:registerEvent("PokemonExperience")
        spawnedMonster:registerEvent("PokemonTargetPriority")
        spawnedMonster:registerEvent("PokemonBattleLock")
    end
    mType.onDisappear = function(monsterInstance, creature)
        if monsterInstance:getId() == creature:getId() then
            PokemonEncounter.release(monsterInstance)
            if PokemonSummon then PokemonSummon.releaseByCreature(monsterInstance:getId()) end
        end
    end
    mType:register(monster)
end
