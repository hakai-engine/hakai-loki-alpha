PokemonTypes = {}

local orderedTypes = {
    "normal", "fire", "water", "electric", "grass", "ice",
    "fighting", "poison", "ground", "flying", "psychic", "bug",
    "rock", "ghost", "dragon", "dark", "steel", "fairy",
}

PokemonTypes.ids = {}
for expectedId, typeName in ipairs(orderedTypes) do
    local nativeId = rawget(_G, "POKEMON_TYPE_" .. string.upper(typeName))
    PokemonTypes.ids[typeName] = nativeId or expectedId
end

if rawget(_G, "POKEMON_TYPE_COUNT") ~= nil then
    assert(POKEMON_TYPE_COUNT == #orderedTypes, "native Pokemon type count mismatch")
    assert(type(ORIGIN_POKEMON) == "number", "native Pokemon combat origin is missing")
    for expectedId, typeName in ipairs(orderedTypes) do
        assert(PokemonTypes.ids[typeName] == expectedId, "native Pokemon type id mismatch: " .. typeName)
    end

    local nativeCategories = {
        PHYSICAL = 1,
        SPECIAL = 2,
        STATUS = 3,
    }
    assert(POKEMON_MOVE_CATEGORY_COUNT == 3, "native Pokemon move category count mismatch")
    for categoryName, expectedId in pairs(nativeCategories) do
        local nativeId = rawget(_G, "POKEMON_MOVE_CATEGORY_" .. categoryName)
        assert(nativeId == expectedId, "native Pokemon move category mismatch: " .. categoryName)
    end
end

local chart = {
    normal = { rock = 0.5, ghost = 0, steel = 0.5 },
    fire = { fire = 0.5, water = 0.5, grass = 2, ice = 2, bug = 2, rock = 0.5, dragon = 0.5, steel = 2 },
    water = { fire = 2, water = 0.5, grass = 0.5, ground = 2, rock = 2, dragon = 0.5 },
    electric = { water = 2, electric = 0.5, grass = 0.5, ground = 0, flying = 2, dragon = 0.5 },
    grass = { fire = 0.5, water = 2, grass = 0.5, poison = 0.5, ground = 2, flying = 0.5, bug = 0.5, rock = 2, dragon = 0.5, steel = 0.5 },
    ice = { fire = 0.5, water = 0.5, grass = 2, ice = 0.5, ground = 2, flying = 2, dragon = 2, steel = 0.5 },
    fighting = { normal = 2, ice = 2, poison = 0.5, flying = 0.5, psychic = 0.5, bug = 0.5, rock = 2, ghost = 0, dark = 2, steel = 2, fairy = 0.5 },
    poison = { grass = 2, poison = 0.5, ground = 0.5, rock = 0.5, ghost = 0.5, steel = 0, fairy = 2 },
    ground = { fire = 2, electric = 2, grass = 0.5, poison = 2, flying = 0, bug = 0.5, rock = 2, steel = 2 },
    flying = { electric = 0.5, grass = 2, fighting = 2, bug = 2, rock = 0.5, steel = 0.5 },
    psychic = { fighting = 2, poison = 2, psychic = 0.5, dark = 0, steel = 0.5 },
    bug = { fire = 0.5, grass = 2, fighting = 0.5, poison = 0.5, flying = 0.5, psychic = 2, ghost = 0.5, dark = 2, steel = 0.5, fairy = 0.5 },
    rock = { fire = 2, ice = 2, fighting = 0.5, ground = 0.5, flying = 2, bug = 2, steel = 0.5 },
    ghost = { normal = 0, psychic = 2, ghost = 2, dark = 0.5 },
    dragon = { dragon = 2, steel = 0.5, fairy = 0 },
    dark = { fighting = 0.5, psychic = 2, ghost = 2, dark = 0.5, fairy = 0.5 },
    steel = { fire = 0.5, water = 0.5, electric = 0.5, ice = 2, rock = 2, steel = 0.5, fairy = 2 },
    fairy = { fire = 0.5, fighting = 2, poison = 0.5, dragon = 2, dark = 2, steel = 0.5 },
}

function PokemonTypes.effectiveness(attackType, defenderTypes)
    local row, multiplier = assert(chart[attackType], "unknown attack type " .. tostring(attackType)), 1
    for _, defenderType in ipairs(defenderTypes) do multiplier = multiplier * (row[defenderType] or 1) end
    return multiplier
end

function PokemonTypes.hasType(types, candidate)
    for _, value in ipairs(types) do if value == candidate then return true end end
    return false
end

function PokemonTypes.id(name)
    return assert(PokemonTypes.ids[name], "unknown Pokemon type " .. tostring(name))
end
