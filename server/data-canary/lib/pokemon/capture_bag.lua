PokemonCaptureBag = {
    DEFAULT_CAPACITY = 20,
    LOCATION = "capture_bag",
    sessions = {},
}

local function requireOwnerGuid(ownerGuid)
    assert(type(ownerGuid) == "number" and ownerGuid > 0, "ownerGuid must be positive")
end

function PokemonCaptureBag.ensureAccount(ownerGuid)
    requireOwnerGuid(ownerGuid)
    return db.query(string.format([[
        INSERT IGNORE INTO `pokemon_capture_bags` (`account_id`, `capacity`)
        SELECT `account_id`, %d FROM `players` WHERE `id` = %d;
    ]], PokemonCaptureBag.DEFAULT_CAPACITY, ownerGuid))
end

local function cloneEntry(entry)
    local copy = {}
    for key, value in pairs(entry) do
        copy[key] = value
    end
    return copy
end

function PokemonCaptureBag.load(player)
    local ownerGuid = player:getGuid()
    PokemonCaptureBag.sessions[ownerGuid] = nil
    local session = {
        capacity = PokemonCaptureBag.capacity(ownerGuid),
        entries = {},
        bySlot = {},
        byInstanceId = {},
    }

    local entries = PokemonCaptureBag.list(ownerGuid)
    for _, entry in ipairs(entries) do
        session.entries[#session.entries + 1] = entry
        session.bySlot[entry.slot] = entry
        session.byInstanceId[tostring(entry.instanceId)] = entry
    end
    PokemonCaptureBag.sessions[ownerGuid] = session
    return session
end

function PokemonCaptureBag.unload(ownerGuid)
    PokemonCaptureBag.sessions[ownerGuid] = nil
end

function PokemonCaptureBag.addInstance(instance)
    local session = PokemonCaptureBag.sessions[instance.ownerGuid]
    if not session then
        return
    end
    local entry = {
        instanceId = tostring(instance.instanceId),
        speciesId = instance.speciesId,
        level = instance.level,
        gender = instance.gender,
        nature = instance.nature,
        currentHp = instance.currentHp,
        maxHp = instance.maxHp,
        slot = instance.locationSlot,
        ballItemId = instance.ballItemId,
        state = instance.state,
    }
    session.entries[#session.entries + 1] = entry
    table.sort(session.entries, function(left, right) return left.slot < right.slot end)
    session.bySlot[entry.slot] = entry
    session.byInstanceId[entry.instanceId] = entry
end

function PokemonCaptureBag.removeInstance(ownerGuid, instanceId)
    local session = PokemonCaptureBag.sessions[ownerGuid]
    if not session then
        return
    end
    local key = tostring(instanceId)
    local entry = session.byInstanceId[key]
    if not entry then
        return
    end
    session.byInstanceId[key] = nil
    session.bySlot[entry.slot] = nil
    for index, candidate in ipairs(session.entries) do
        if tostring(candidate.instanceId) == key then
            table.remove(session.entries, index)
            break
        end
    end
end

function PokemonCaptureBag.updateInstance(instance)
    local session = PokemonCaptureBag.sessions[instance.ownerGuid]
    if not session then
        return
    end
    local entry = session.byInstanceId[tostring(instance.instanceId)]
    if not entry then
        return
    end
    entry.speciesId = instance.speciesId
    entry.level = instance.level
    entry.gender = instance.gender
    entry.nature = instance.nature
    entry.currentHp = instance.currentHp
    entry.maxHp = instance.maxHp
    entry.ballItemId = instance.ballItemId
    entry.state = instance.state
end

function PokemonCaptureBag.healSession(ownerGuid)
	local session = PokemonCaptureBag.sessions[ownerGuid]
	if not session then
		return
	end
	for _, entry in ipairs(session.entries) do
		entry.currentHp = entry.maxHp
		entry.state = "ready"
	end
end

function PokemonCaptureBag.getBySlot(ownerGuid, slot)
    local session = PokemonCaptureBag.sessions[ownerGuid]
    if session then
        return session.bySlot[slot]
    end
    local entries = PokemonCaptureBag.list(ownerGuid)
    for _, entry in ipairs(entries) do
        if entry.slot == slot then
            return entry
        end
    end
    return nil
end

function PokemonCaptureBag.getByInstanceId(ownerGuid, instanceId)
    local session = PokemonCaptureBag.sessions[ownerGuid]
    if session then
        return session.byInstanceId[tostring(instanceId)]
    end
    return nil
end

function PokemonCaptureBag.capacity(ownerGuid)
    requireOwnerGuid(ownerGuid)
    local session = PokemonCaptureBag.sessions[ownerGuid]
    if session then
        return session.capacity
    end
    PokemonCaptureBag.ensureAccount(ownerGuid)
    local resultId = db.storeQuery(string.format([[
        SELECT `b`.`capacity`
        FROM `pokemon_capture_bags` AS `b`
        INNER JOIN `players` AS `p` ON `p`.`account_id` = `b`.`account_id`
        WHERE `p`.`id` = %d
        LIMIT 1;
    ]], ownerGuid))
    if not resultId then
        return PokemonCaptureBag.DEFAULT_CAPACITY
    end
    local capacity = Result.getNumber(resultId, "capacity")
    Result.free(resultId)
    return capacity
end

function PokemonCaptureBag.firstFreeSlot(ownerGuid)
    local capacity = PokemonCaptureBag.capacity(ownerGuid)
    local session = PokemonCaptureBag.sessions[ownerGuid]
    if session then
        for slot = 1, capacity do
            if not session.bySlot[slot] then
                return slot, capacity
            end
        end
        return nil, capacity
    end
    local occupied = {}
    local resultId = db.storeQuery(string.format([[
        SELECT `location_slot`
        FROM `pokemon_instances`
        WHERE `owner_id` = %d AND `location_type` = %s AND `location_slot` IS NOT NULL;
    ]], ownerGuid, db.escapeString(PokemonCaptureBag.LOCATION)))
    if resultId then
        repeat
            occupied[Result.getNumber(resultId, "location_slot")] = true
        until not Result.next(resultId)
        Result.free(resultId)
    end

    for slot = 1, capacity do
        if not occupied[slot] then
            return slot, capacity
        end
    end
    return nil, capacity
end

function PokemonCaptureBag.hasSpace(ownerGuid)
    local slot, capacity = PokemonCaptureBag.firstFreeSlot(ownerGuid)
    return slot ~= nil, slot, capacity
end

function PokemonCaptureBag.list(ownerGuid)
    requireOwnerGuid(ownerGuid)
    local session = PokemonCaptureBag.sessions[ownerGuid]
    if session then
        local entries = {}
        for _, entry in ipairs(session.entries) do
            entries[#entries + 1] = cloneEntry(entry)
        end
        return entries
    end
    local entries = {}
    local resultId = db.storeQuery(string.format([[
        SELECT `id`, `species_id`, `level`, `gender`, `nature`, `current_hp`, `max_hp`,
               `location_slot`, `ball_item_id`, `state`
        FROM `pokemon_instances`
        WHERE `owner_id` = %d AND `location_type` = %s
        ORDER BY `location_slot`;
    ]], ownerGuid, db.escapeString(PokemonCaptureBag.LOCATION)))
    if not resultId then
        return entries
    end
    repeat
        entries[#entries + 1] = {
            instanceId = Result.getString(resultId, "id"),
            speciesId = Result.getNumber(resultId, "species_id"),
            level = Result.getNumber(resultId, "level"),
            gender = Result.getString(resultId, "gender"),
            nature = Result.getString(resultId, "nature"),
            currentHp = Result.getNumber(resultId, "current_hp"),
            maxHp = Result.getNumber(resultId, "max_hp"),
            slot = Result.getNumber(resultId, "location_slot"),
            ballItemId = Result.getNumber(resultId, "ball_item_id"),
            state = Result.getString(resultId, "state"),
        }
    until not Result.next(resultId)
    Result.free(resultId)
    return entries
end

function PokemonCaptureBag.expand(ownerGuid, slots)
    requireOwnerGuid(ownerGuid)
    assert(type(slots) == "number" and slots > 0 and slots == math.floor(slots), "slots must be a positive integer")
    PokemonCaptureBag.ensureAccount(ownerGuid)
    local expanded = db.query(string.format([[
        UPDATE `pokemon_capture_bags` AS `b`
        INNER JOIN `players` AS `p` ON `p`.`account_id` = `b`.`account_id`
        SET `b`.`capacity` = `b`.`capacity` + %d
        WHERE `p`.`id` = %d;
    ]], slots, ownerGuid))
    if expanded and PokemonCaptureBag.sessions[ownerGuid] then
        PokemonCaptureBag.sessions[ownerGuid].capacity = PokemonCaptureBag.sessions[ownerGuid].capacity + slots
    end
    return expanded
end
