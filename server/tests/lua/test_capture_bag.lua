local passed, failed = 0, 0
local occupied, configuredCapacity = {}, 20

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write(string.format("FAIL %s: %s\n", name, err))
    end
end

local function equal(actual, expected)
    assert(actual == expected, string.format("expected %s, got %s", tostring(expected), tostring(actual)))
end

local handles, nextHandle = {}, 1
local function handle(rows)
    if #rows == 0 then return nil end
    local id = nextHandle
    nextHandle = nextHandle + 1
    handles[id] = { rows = rows, index = 1 }
    return id
end

db = {
    query = function() return true end,
    escapeString = function(value) return "'" .. tostring(value) .. "'" end,
    storeQuery = function(query)
        if query:find("`b`.`capacity`", 1, true) then
            return handle({ { capacity = configuredCapacity } })
        end
        if query:find("`location_slot`", 1, true) then
            local rows = {}
            for _, slot in ipairs(occupied) do rows[#rows + 1] = { location_slot = slot } end
            return handle(rows)
        end
        return nil
    end,
}

Result = {
    getNumber = function(id, column)
        return handles[id].rows[handles[id].index][column]
    end,
    next = function(id)
        handles[id].index = handles[id].index + 1
        return handles[id].rows[handles[id].index] ~= nil
    end,
    free = function(id) handles[id] = nil end,
}

dofile("data-canary/lib/pokemon/capture_bag.lua")

test("empty bag starts at slot one", function()
    occupied, configuredCapacity = {}, 20
    local slot, capacity = PokemonCaptureBag.firstFreeSlot(42)
    equal(slot, 1)
    equal(capacity, 20)
end)

test("allocator fills first gap", function()
    occupied, configuredCapacity = { 1, 3, 4 }, 20
    local slot = PokemonCaptureBag.firstFreeSlot(42)
    equal(slot, 2)
end)

test("full bag refuses allocation", function()
    occupied, configuredCapacity = { 1, 2, 3 }, 3
    local slot, capacity = PokemonCaptureBag.firstFreeSlot(42)
    equal(slot, nil)
    equal(capacity, 3)
end)

test("hasSpace reports allocated slot", function()
    occupied, configuredCapacity = { 1 }, 2
    local hasSpace, slot, capacity = PokemonCaptureBag.hasSpace(42)
    equal(hasSpace, true)
    equal(slot, 2)
    equal(capacity, 2)
end)

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
