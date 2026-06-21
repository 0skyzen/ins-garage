---@param garage table
---@return table<string, boolean>? set of allowed vehicle types, nil = allow all
local function allowedTypes(garage)
    if not garage.types then return nil end
    local set = {}
    for _, t in ipairs(garage.types) do set[t] = true end
    return set
end

---@param row table database row
---@param personal boolean true when the viewer owns it directly (not job/shared)
---@return table entry light table for the client menu
local function buildVehicleEntry(row, personal)
    local model, body, engine, fuel
    if row.vehicle then
        local ok, props = pcall(json.decode, row.vehicle)
        if ok and props then
            model = props.model
            body = props.bodyHealth
            engine = props.engineHealth
            fuel = props.fuelLevel
        end
    end
    return {
        plate = row.plate,
        model = model,
        type = row.type,
        category_id = row.category_id,
        category_name = row.category_name,
        owner = row.owner,
        personal = personal,
        body = body,
        engine = engine,
        fuel = fuel,
    }
end

---@param rows table[] database rows
---@param types table<string, boolean>? allowed vehicle types, nil = all
---@param personalFor string? identifier marking entries as personally owned
---@return table[] entries filtered by type
local function collect(rows, types, personalFor)
    local out = {}
    for _, row in ipairs(rows) do
        if not types or types[row.type] then
            out[#out + 1] = buildVehicleEntry(row, personalFor and row.owner == personalFor or false)
        end
    end
    return out
end

---@param source number
---@param garageIndex number index into Config.Garages
---@return table? data { owned, out, shared, categories } or { denied = true }
lib.callback.register('ins-garages:getGarage', function(source, garageIndex)
    local identifier, job = GetPlayerData(source)
    if not identifier then return end

    local garage = Config.Garages[garageIndex]
    if not garage then return end

    if garage.job and job ~= garage.job then
        return { denied = true }
    end

    local types = allowedTypes(garage)

    return {
        owned = collect(Db.GetVehicles(identifier, job, true), types, identifier),
        out = collect(Db.GetVehicles(identifier, job, false), types, identifier),
        shared = collect(Db.GetSharedVehicles(identifier), types, nil),
        categories = Db.GetCategories(identifier),
    }
end)

---@param source number
---@param plate string
---@return boolean success
---@return string message
lib.callback.register('ins-garages:recover', function(source, plate)
    local identifier, job = GetPlayerData(source)
    if not identifier then return false end

    plate = Db.NormalizePlate(plate)
    if not Db.CanAccessVehicle(identifier, plate, job) then
        return false, locale('not_your_vehicle')
    end

    if Db.IsStored(plate) then
        return false, locale('already_stored')
    end

    if Config.RecoverFee > 0 and not Framework.RemoveMoney(source, Config.RecoverFee) then
        return false, locale('recover_no_money', Config.RecoverFee)
    end

    Db.SetStoredFlag(plate, true)
    return true, locale('recovered')
end)

---@param source number
---@param plate string
---@return boolean success
---@return table|string props to spawn on success, or an error message
lib.callback.register('ins-garages:takeOut', function(source, plate)
    local identifier, job = GetPlayerData(source)
    if not identifier then return false end

    plate = Db.NormalizePlate(plate)
    if not Db.CanAccessVehicle(identifier, plate, job) then
        return false, locale('no_access')
    end

    if not Db.IsStored(plate) then
        return false, locale('not_in_garage')
    end

    local raw = MySQL.scalar.await('SELECT `vehicle` FROM `owned_vehicles` WHERE `plate` = ?', { plate })
    local props
    if raw then
        local ok, decoded = pcall(json.decode, raw)
        if ok then props = decoded end
    end
    props = props or {}
    props.plate = plate

    Db.SetStored(plate, false, raw)
    return true, props
end)

---@param h number? model hash
---@return number? unsigned hash so client and server values compare equal
local function normHash(h)
    h = tonumber(h)
    if not h then return nil end
    return math.floor(h) & 0xFFFFFFFF
end

---@param source number
---@param plate string
---@param props table vehicle properties from the client
---@param netId number? network id used to read the real model server-side
---@return boolean success
---@return string message
lib.callback.register('ins-garages:store', function(source, plate, props, netId)
    local identifier, job = GetPlayerData(source)
    if not identifier then return false end

    plate = Db.NormalizePlate(plate)
    if not Db.CanAccessVehicle(identifier, plate, job) then
        return false, locale('not_your_vehicle')
    end

    if Db.IsStored(plate) then
        return false, locale('already_stored')
    end

    local registered = Db.GetVehicleModel(plate)
    if registered then
        local actual = props and props.model
        if netId then
            local entity = NetworkGetEntityFromNetworkId(netId)
            if entity and entity ~= 0 and DoesEntityExist(entity) then
                actual = GetEntityModel(entity)
            end
        end
        if actual and normHash(actual) ~= normHash(registered) then
            return false, locale('plate_mismatch')
        end
    end

    local encoded = type(props) == 'table' and json.encode(props) or nil
    Db.SetStored(plate, true, encoded)
    return true, locale('vehicle_stored')
end)
