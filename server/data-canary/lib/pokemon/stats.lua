PokemonStats = {}

local natureEffects = {
    lonely={up="attack",down="defense"}, brave={up="attack",down="speed"}, adamant={up="attack",down="specialAttack"}, naughty={up="attack",down="specialDefense"},
    bold={up="defense",down="attack"}, relaxed={up="defense",down="speed"}, impish={up="defense",down="specialAttack"}, lax={up="defense",down="specialDefense"},
    timid={up="speed",down="attack"}, hasty={up="speed",down="defense"}, jolly={up="speed",down="specialAttack"}, naive={up="speed",down="specialDefense"},
    modest={up="specialAttack",down="attack"}, mild={up="specialAttack",down="defense"}, quiet={up="specialAttack",down="speed"}, rash={up="specialAttack",down="specialDefense"},
    calm={up="specialDefense",down="attack"}, gentle={up="specialDefense",down="defense"}, sassy={up="specialDefense",down="speed"}, careful={up="specialDefense",down="specialAttack"},
}

function PokemonStats.natureMultiplier(nature, stat)
    if not PokemonRules.naturesAffectStats or not PokemonCombatConfig.nature.enabled then return 1 end
    local effect = natureEffects[nature]
    if not effect then return 1 end
    if effect.up == stat then return PokemonCombatConfig.nature.raised end
    if effect.down == stat then return PokemonCombatConfig.nature.lowered end
    return 1
end

function PokemonStats.calculate(species, level, ivs, nature, gender)
    local result, ivEnabled = {}, PokemonRules.ivsAffectStats
    level = PokemonCombatConfig.effectiveLevel(level)
	local levelMultiplier = PokemonCombatConfig.levelStatMultiplier(level)
    for _, stat in ipairs(PokemonConstants.STAT_KEYS) do
        local iv = ivEnabled and (ivs and ivs[stat] or 0) or 0
        local base = species.baseStats[stat] + iv
        if stat == "hp" then
            result.hp = math.max(1, math.ceil(base * levelMultiplier * PokemonCombatConfig.genderHpMultiplier(gender)))
        else
			result[stat] = math.max(1, math.ceil(base * levelMultiplier * PokemonStats.natureMultiplier(nature, stat)))
		end
    end
    return result
end
