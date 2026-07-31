PokemonMoves = {}

PokemonMoves.DAMAGE_SCALING = {
    NONE = "none",
    ATTACK = "attack",
    SPECIAL_ATTACK = "special_attack",
    USER_SPEED = "user_speed",
}

PokemonMoves.POWER_RULES = {
    FIXED = "fixed",
    FASTER_THAN_TARGET = "faster_than_target",
    SLOWER_THAN_TARGET = "slower_than_target",
}

local definitions = {
    -- Internal combat action installed for every Pokemon by the factory.
    -- It is not a visible move slot and is not announced.
    basic_attack = {
        id="basic_attack", coreId=1, name="Basic Attack", type="normal",
        category="physical", power=35, cooldown=1600, range=1,
        chance=100, effect=nil, basic=true, announce=false
    },
    tackle = { id="tackle", coreId=2, name="Tackle", type="normal", category="physical", power=40, cooldown=2000, range=1, chance=100, effect="hit" },
    vine_whip = { id="vine_whip", coreId=3, name="Vine Whip", type="grass", category="physical", power=45, cooldown=2500, range=3, chance=35, effect="vine" },
    ember = { id="ember", coreId=4, name="Ember", type="fire", category="special", power=40, cooldown=2500, range=5, chance=35, effect="fire" },
    flamethrower = { id="flamethrower", coreId=5, name="Flamethrower", type="fire", category="special", power=90, cooldown=5000, range=6, chance=20, effect="fire" },
    water_gun = { id="water_gun", coreId=6, name="Water Gun", type="water", category="special", power=40, cooldown=2500, range=5, chance=35, effect="water" },
    karate_chop = { id="karate_chop", coreId=7, name="Karate Chop", type="fighting", category="physical", power=50, cooldown=2805, range=2, chance=32, effect="fighting_hit" },
    mega_punch = { id="mega_punch", coreId=8, name="Mega Punch", type="normal", category="physical", power=80, cooldown=3200, range=1, chance=28, effect="heavy_punch" },
    mega_kick = { id="mega_kick", coreId=9, name="Mega Kick", type="normal", category="physical", power=120, cooldown=4800, range=1, chance=20, effect="heavy_kick" },
    cross_chop = { id="cross_chop", coreId=10, name="Cross Chop", type="fighting", category="physical", power=100, cooldown=5200, range=1, chance=20, effect="cross_chop" },
    dynamic_punch = { id="dynamic_punch", coreId=11, name="Dynamic Punch", type="fighting", category="physical", power=100, cooldown=6500, range=1, chance=16, effect="dynamic_punch" },
    earthquake = {
        id="earthquake", coreId=12, name="Earthquake", type="ground",
        category="physical", power=100, cooldown=8000, range=1,
        chance=100, effect="earthquake", area="diamond5", areaOrigin="self",
        pulses=4, pulseInterval=320, jumpHeight=20,
        jumpDuration=280, shakeIntensity=6, shakeDuration=300
    },
    solar_beam = {
        id="solar_beam", coreId=13, name="Solar Beam", type="grass",
        category="special", power=120, cooldown=9000, range=5,
        chance=100, effect="solar_beam", area="forward3x6"
    },
    electro_ball = {
        id="electro_ball", coreId=14, name="Electro Ball", type="electric",
        category="special", power=40, cooldown=4500, range=5,
        chance=100, effect="electro_ball",
        damageScaling=PokemonMoves.DAMAGE_SCALING.SPECIAL_ATTACK,
        powerRule=PokemonMoves.POWER_RULES.FASTER_THAN_TARGET
    },
    gyro_ball = {
        id="gyro_ball", coreId=15, name="Gyro Ball", type="steel",
        category="physical", power=1, cooldown=4200, range=1,
        chance=100, effect="gyro_ball",
        damageScaling=PokemonMoves.DAMAGE_SCALING.ATTACK,
        powerRule=PokemonMoves.POWER_RULES.SLOWER_THAN_TARGET,
        maximumPower=150
    },
    thunder_shock = {
        id="thunder_shock", coreId=16, name="Thunder Shock", type="electric",
        category="special", power=40, accuracy=100, cooldown=2200, range=5,
        chance=35, effect="thunder_shock",
        effects={{trigger="after_hit",kind="status",status="paralysis",chance=10}}
    },
    thunderbolt = {
        id="thunderbolt", coreId=17, name="Thunderbolt", type="electric",
        category="special", power=90, accuracy=100, cooldown=5000, range=5,
        chance=22, effect="thunderbolt",
        effects={{trigger="after_hit",kind="status",status="paralysis",chance=10}}
    },
    thunder_wave = {
        id="thunder_wave", coreId=18, name="Thunder Wave", type="electric",
        category="status", power=0, accuracy=90, cooldown=6000, range=5,
        chance=18, effect="thunder_wave",
        effects={{trigger="on_cast",kind="status",status="paralysis",chance=100}}
    },
    spark = {
        id="spark", coreId=19, name="Spark", type="electric",
        category="physical", power=65, accuracy=100, cooldown=3200, range=1,
        chance=28, effect="spark",
        effects={{trigger="after_hit",kind="status",status="paralysis",chance=30}}
    },
    swift = {
        id="swift", coreId=20, name="Swift", type="normal",
        category="special", power=60, accuracy=100, alwaysHits=true,
        cooldown=3500, range=5, chance=26, effect="swift"
    },
    agility = {
        id="agility", coreId=21, name="Agility", type="psychic",
        category="status", power=0, accuracy=100, cooldown=10000, range=0,
        chance=15, effect="agility", targetMode="self",
        effects={{trigger="on_cast",kind="stat_stage",stat="speed",stages=2,target="self"}}
    },
    slam = {
        id="slam", coreId=22, name="Slam", type="normal",
        category="physical", power=80, accuracy=75, cooldown=4000, range=1,
        chance=24, effect="slam"
    },
    thunder = {
        id="thunder", coreId=23, name="Thunder", type="electric",
        category="special", power=110, accuracy=70, cooldown=7500, range=6,
        chance=14, effect="thunder",
        effects={{trigger="after_hit",kind="status",status="paralysis",chance=30}}
    },
    volt_tackle = {
        id="volt_tackle", coreId=24, name="Volt Tackle", type="electric",
        category="physical", power=120, accuracy=100, cooldown=7000, range=1,
        chance=14, effect="volt_tackle",
        effects={
            {trigger="after_hit",kind="status",status="paralysis",chance=10},
            {trigger="after_hit",kind="recoil",fraction=1/3,target="self"}
        }
    },
    discharge = {
        id="discharge", coreId=25, name="Discharge", type="electric",
        category="special", power=80, accuracy=100, cooldown=6500, range=1,
        chance=16, effect="discharge", area="circle3", areaOrigin="self",
        effects={{trigger="after_hit",kind="status",status="paralysis",chance=30}}
    },
    thunder_punch = {
        id="thunder_punch", coreId=26, name="Thunder Punch", type="electric",
        category="physical", power=75, accuracy=100, cooldown=3800, range=1,
        chance=25, effect="thunder_punch",
        effects={{trigger="after_hit",kind="status",status="paralysis",chance=10}}
    },
    razor_leaf = {
        id="razor_leaf", coreId=27, name="Razor Leaf", type="grass",
        category="physical", power=55, accuracy=95, cooldown=3000, range=5,
        chance=30, effect="razor_leaf", criticalStage=1
    },
    leech_seed = {
        id="leech_seed", coreId=28, name="Leech Seed", type="grass",
        category="status", power=0, accuracy=90, cooldown=6500, range=5,
        chance=18, effect="leech_seed",
        effects={{trigger="on_cast",kind="leech_seed",duration=6000,interval=1000,fraction=1/16}}
    },
    sleep_powder = {
        id="sleep_powder", coreId=29, name="Sleep Powder", type="grass",
        category="status", power=0, accuracy=75, cooldown=8000, range=5,
        chance=14, effect="sleep_powder", area="diamond7",
        effects={{trigger="on_cast",kind="status",status="sleep",chance=100,duration=5000}}
    },
    poison_powder = {
        id="poison_powder", coreId=30, name="Poison Powder", type="poison",
        category="status", power=0, accuracy=75, cooldown=7000, range=5,
        chance=16, effect="poison_powder", area="diamond7",
        effects={{trigger="on_cast",kind="status",status="poison",chance=100,duration=6000,interval=1000,fraction=1/16}}
    },
    seed_bomb = {
        id="seed_bomb", coreId=31, name="Seed Bomb", type="grass",
        category="physical", power=80, accuracy=100, cooldown=4500, range=5,
        chance=24, effect="seed_bomb", area="diamond7", areaOrigin="target"
    },
    energy_ball = {
        id="energy_ball", coreId=32, name="Energy Ball", type="grass",
        category="special", power=90, accuracy=100, cooldown=5000, range=5,
        chance=22, effect="energy_ball"
    },
    sludge_bomb = {
        id="sludge_bomb", coreId=33, name="Sludge Bomb", type="poison",
        category="special", power=90, accuracy=100, cooldown=5500, range=5,
        chance=20, effect="sludge_bomb", area="diamond7", areaOrigin="target",
        effects={{trigger="after_hit",kind="status",status="poison",chance=30,duration=6000,interval=1000,fraction=1/16}}
    },
    synthesis = {
        id="synthesis", coreId=34, name="Synthesis", type="grass",
        category="status", power=0, accuracy=100, cooldown=10000, range=0,
        chance=12, effect="synthesis", targetMode="self",
        effects={{trigger="on_cast",kind="heal",target="self",fraction=0.5}}
    },
    body_slam = {
        id="body_slam", coreId=35, name="Body Slam", type="normal",
        category="physical", power=85, accuracy=100, cooldown=4500, range=1,
        chance=22, effect="body_slam", jumpHeight=15, jumpDuration=300,
        effects={{trigger="after_hit",kind="status",status="paralysis",chance=30}}
    },
    headbutt = {
        id="headbutt", coreId=36, name="Headbutt", type="normal",
        category="physical", power=70, accuracy=100, cooldown=3000, range=1,
        chance=30, effect="headbutt"
    },
    petal_dance = {
        id="petal_dance", coreId=37, name="Petal Dance", type="grass",
        category="special", power=120, accuracy=100, cooldown=7000, range=4,
        chance=16, effect="petal_dance", area="forward5x4"
    },
    power_whip = {
        id="power_whip", coreId=38, name="Power Whip", type="grass",
        category="physical", power=120, accuracy=85, cooldown=7000, range=1,
        chance=16, effect="power_whip", area="diamond7", areaOrigin="self"
    },
    petal_blizzard = {
        id="petal_blizzard", coreId=39, name="Petal Blizzard", type="grass",
        category="special", power=90, accuracy=100, cooldown=7000, range=1,
        chance=16, effect="petal_blizzard", area="diamond11", areaOrigin="self"
    },
    hyper_beam = {
        id="hyper_beam", coreId=40, name="Hyper Beam", type="normal",
        category="special", power=150, accuracy=90, cooldown=10000, range=6,
        chance=10, effect="hyper_beam", area="forward3x6"
    },
}

local learnsets = {
    [1]={
        "vine_whip","razor_leaf","leech_seed","sleep_powder","poison_powder","seed_bomb",
        "energy_ball","sludge_bomb","synthesis","solar_beam","body_slam","headbutt"
    },
    [2]={
        "vine_whip","razor_leaf","leech_seed","sleep_powder","seed_bomb","energy_ball",
        "sludge_bomb","petal_dance","synthesis","solar_beam","body_slam","headbutt"
    },
    [3]={
        "razor_leaf","petal_dance","solar_beam","energy_ball","sludge_bomb","sleep_powder",
        "power_whip","petal_blizzard","synthesis","earthquake","hyper_beam","body_slam"
    },
    [4]={"tackle","ember"}, [5]={"tackle","ember"}, [6]={"tackle","ember","flamethrower","earthquake"},
    [7]={"tackle","water_gun"}, [8]={"tackle","water_gun"}, [9]={"tackle","water_gun"},
    [25]={
        "thunder_shock","thunderbolt","thunder_wave","spark","electro_ball","swift",
        "agility","slam","thunder","volt_tackle","discharge","thunder_punch"
    },
    -- The legacy Machamp relation is the visual/cooldown reference. Only moves
    -- valid for Machamp in the canonical Pokemon learnset are enabled here.
    [68]={"karate_chop","mega_punch","mega_kick","cross_chop","dynamic_punch","earthquake"},
    [95]={"gyro_ball"},
}

local generatedKanto = dofile(DATA_DIRECTORY .. "/lib/pokemon/kanto_moves_generated.lua")
for moveId, move in pairs(generatedKanto.definitions) do
    if not definitions[moveId] then definitions[moveId] = move end
end
for speciesId, moveIds in pairs(generatedKanto.learnsets) do
    learnsets[speciesId] = moveIds
end

-- Curated geometry hints consumed by the native Canary MonsterType adapter.
-- They do not position effects or execute combat independently.
local curatedOverrides = {
    vine_whip = { area = "vine_whip_wave", range = 8 },
    flamethrower = { area = "forward3x5", range = 6 },
    water_gun = { area = "forward3x6", range = 5 },
    aqua_jet = { area = "forward3x6" },
    aurora_beam = { area = "forward3x6" },
    brick_break = { area = "forward3x3" },
    bulldoze = { area = "forward1x5" },
    flash_cannon = { area = "forward3x6" },
    focus_blast = { area = "forward3x5" },
    frost_breath = { area = "forward3x3" },
    fury_cutter = { area = "forward3x1" },
    gust = { area = "forward3x6_taper" },
    hammer_arm = { area = "forward3x3" },
    ice_beam = { area = "forward3x6" },
    overheat = { area = "forward3x5" },
    psybeam = { area = "forward1x5" },
    sand_attack = { area = "forward1x2" },
    signal_beam = { area = "forward1x6" },
    zap_cannon = { area = "forward3x6" },
    dragon_breath = { area = "dragon_breath", range = 4 },
    air_slash = { area = "circle5", areaOrigin = "self", range = 4 },
    fire_blast = { area = "forward3x6", range = 6 },
    heat_wave = { area = "heat_wave", range = 5 },
    inferno = { area = "square7", areaOrigin = "target", range = 5 },
    wing_attack = { area = "forward3x1", range = 1 },
}
for moveId, fields in pairs(curatedOverrides) do
    local move = assert(definitions[moveId], "missing generated Pokemon move " .. moveId)
    for key, value in pairs(fields) do move[key] = value end
end

local validDamageScaling = {
    [PokemonMoves.DAMAGE_SCALING.NONE] = true,
    [PokemonMoves.DAMAGE_SCALING.ATTACK] = true,
    [PokemonMoves.DAMAGE_SCALING.SPECIAL_ATTACK] = true,
    [PokemonMoves.DAMAGE_SCALING.USER_SPEED] = true,
}

local validPowerRules = {
    [PokemonMoves.POWER_RULES.FIXED] = true,
    [PokemonMoves.POWER_RULES.FASTER_THAN_TARGET] = true,
    [PokemonMoves.POWER_RULES.SLOWER_THAN_TARGET] = true,
}

local function defaultDamageScaling(move)
    if move.category == "physical" then return PokemonMoves.DAMAGE_SCALING.ATTACK end
    if move.category == "special" then return PokemonMoves.DAMAGE_SCALING.SPECIAL_ATTACK end
    return PokemonMoves.DAMAGE_SCALING.NONE
end

for id, move in pairs(definitions) do
    move.damageScaling = move.damageScaling or defaultDamageScaling(move)
    move.powerRule = move.powerRule or PokemonMoves.POWER_RULES.FIXED
    move.accuracy = move.accuracy or 100
    move.targetMode = move.targetMode or "target"
    assert(move.id == id, "Pokemon move registry key must match move.id")
    assert(validDamageScaling[move.damageScaling], "invalid damageScaling for Pokemon move " .. id)
    assert(validPowerRules[move.powerRule], "invalid powerRule for Pokemon move " .. id)
    assert(move.accuracy >= 1 and move.accuracy <= 100, "invalid accuracy for Pokemon move " .. id)
    assert(move.targetMode == "target" or move.targetMode == "self", "invalid targetMode for Pokemon move " .. id)
end

function PokemonMoves.get(id) return definitions[id] end
function PokemonMoves.all() return definitions end

function PokemonMoves.attackStatKey(move)
    if move.damageScaling == PokemonMoves.DAMAGE_SCALING.ATTACK then return "attack" end
    if move.damageScaling == PokemonMoves.DAMAGE_SCALING.SPECIAL_ATTACK then return "specialAttack" end
    if move.damageScaling == PokemonMoves.DAMAGE_SCALING.USER_SPEED then return "speed" end
    error("invalid damageScaling for Pokemon move " .. tostring(move.id))
end

function PokemonMoves.resolvePower(move, attackerStats, defenderStats)
    if move.powerRule == PokemonMoves.POWER_RULES.FIXED or not defenderStats then
        return move.power
    end

    local attackerSpeed = math.max(1, attackerStats.speed)
    local defenderSpeed = math.max(1, defenderStats.speed)
    if move.powerRule == PokemonMoves.POWER_RULES.FASTER_THAN_TARGET then
        local ratio = attackerSpeed / defenderSpeed
        if ratio >= 4 then return 150 end
        if ratio >= 3 then return 120 end
        if ratio >= 2 then return 80 end
        if ratio >= 1 then return 60 end
        return 40
    end

    if move.powerRule == PokemonMoves.POWER_RULES.SLOWER_THAN_TARGET then
        return math.min(move.maximumPower or 150, math.floor(25 * defenderSpeed / attackerSpeed) + 1)
    end

    error("invalid powerRule for Pokemon move " .. tostring(move.id))
end

function PokemonMoves.forSpecies(speciesId)
    local result = {}
    for _, id in ipairs(learnsets[speciesId] or {}) do table.insert(result, assert(definitions[id])) end
    return result
end
