local passed, failed = 0, 0

local function test(name, callback)
  local ok, err = pcall(callback)
  if ok then
    passed = passed + 1
  else
    failed = failed + 1
    io.stderr:write(string.format('FAIL %s: %s\n', name, err))
  end
end

local function equal(actual, expected)
  assert(actual == expected, string.format('expected %s, got %s', tostring(expected), tostring(actual)))
end

local domainPath = 'modules/game_hakai_pokemon_domain/pokemon_domain.lua'
if g_resources then
  domainPath = '/modules/game_hakai_pokemon_domain/pokemon_domain.lua'
end
dofile(domainPath)

test('type ids match the Odin contract', function()
  local orderedTypes = {
    'normal', 'fire', 'water', 'electric', 'grass', 'ice',
    'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug',
    'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy',
  }
  equal(PokemonDomain.TYPE_COUNT, #orderedTypes)
  for expectedId, key in ipairs(orderedTypes) do
    equal(PokemonDomain.getTypeId(key), expectedId)
    equal(PokemonDomain.getTypeKey(expectedId), key)
  end
end)

test('move category ids match the Odin contract', function()
  equal(PokemonDomain.MoveCategory.PHYSICAL, 1)
  equal(PokemonDomain.MoveCategory.SPECIAL, 2)
  equal(PokemonDomain.MoveCategory.STATUS, 3)
  equal(PokemonDomain.getMoveCategoryKey(1), 'physical')
  equal(PokemonDomain.getMoveCategoryKey(2), 'special')
  equal(PokemonDomain.getMoveCategoryKey(3), 'status')
end)

test('unknown values are rejected', function()
  equal(PokemonDomain.getTypeId('stellar'), nil)
  equal(PokemonDomain.getTypeKey(255), nil)
  equal(PokemonDomain.isValidTypeId(0), false)
  equal(PokemonDomain.isValidMoveCategoryId(0), false)
end)

test('lookups normalize string case and numeric strings', function()
  equal(PokemonDomain.getTypeId('FiRe'), 2)
  equal(PokemonDomain.getTypeKey('18'), 'fairy')
  equal(PokemonDomain.getMoveCategoryId('SPECIAL'), 2)
end)

print(string.format('%d passed, %d failed', passed, failed))
os.exit(failed == 0 and 0 or 1)
