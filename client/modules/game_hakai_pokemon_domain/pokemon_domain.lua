PokemonDomain = {
  VERSION = 1,
  TYPE_COUNT = 18,
  MOVE_CATEGORY_COUNT = 3,
  Type = {
    NONE = 0,
    NORMAL = 1,
    FIRE = 2,
    WATER = 3,
    ELECTRIC = 4,
    GRASS = 5,
    ICE = 6,
    FIGHTING = 7,
    POISON = 8,
    GROUND = 9,
    FLYING = 10,
    PSYCHIC = 11,
    BUG = 12,
    ROCK = 13,
    GHOST = 14,
    DRAGON = 15,
    DARK = 16,
    STEEL = 17,
    FAIRY = 18,
  },
  MoveCategory = {
    NONE = 0,
    PHYSICAL = 1,
    SPECIAL = 2,
    STATUS = 3,
  },
}

local orderedTypeKeys = {
  'normal', 'fire', 'water', 'electric', 'grass', 'ice',
  'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug',
  'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy',
}

local orderedMoveCategoryKeys = {
  'physical', 'special', 'status',
}

local typeIdsByKey = {}
local typeKeysById = {}
local moveCategoryIdsByKey = {}
local moveCategoryKeysById = {}

for expectedId, key in ipairs(orderedTypeKeys) do
  local enumId = PokemonDomain.Type[string.upper(key)]
  assert(enumId == expectedId, 'Pokemon type contract mismatch: ' .. key)
  typeIdsByKey[key] = enumId
  typeKeysById[enumId] = key
end

for expectedId, key in ipairs(orderedMoveCategoryKeys) do
  local enumId = PokemonDomain.MoveCategory[string.upper(key)]
  assert(enumId == expectedId, 'Pokemon move category contract mismatch: ' .. key)
  moveCategoryIdsByKey[key] = enumId
  moveCategoryKeysById[enumId] = key
end

assert(#orderedTypeKeys == PokemonDomain.TYPE_COUNT, 'Pokemon type count mismatch')
assert(#orderedMoveCategoryKeys == PokemonDomain.MOVE_CATEGORY_COUNT, 'Pokemon move category count mismatch')

function PokemonDomain.getTypeId(key)
  if type(key) ~= 'string' then return nil end
  return typeIdsByKey[string.lower(key)]
end

function PokemonDomain.getTypeKey(id)
  return typeKeysById[tonumber(id)]
end

function PokemonDomain.isValidTypeId(id)
  return PokemonDomain.getTypeKey(id) ~= nil
end

function PokemonDomain.getMoveCategoryId(key)
  if type(key) ~= 'string' then return nil end
  return moveCategoryIdsByKey[string.lower(key)]
end

function PokemonDomain.getMoveCategoryKey(id)
  return moveCategoryKeysById[tonumber(id)]
end

function PokemonDomain.isValidMoveCategoryId(id)
  return PokemonDomain.getMoveCategoryKey(id) ~= nil
end
