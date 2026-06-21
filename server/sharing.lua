local blacklistedHashes = {}
for _, name in ipairs(Config.ShareBlacklist) do
    blacklistedHashes[GetHashKey(name)] = true
end

---@param plate string
---@return boolean true if the vehicle's model is in Config.ShareBlacklist
local function isBlacklistedPlate(plate)
    local raw = MySQL.scalar.await('SELECT `vehicle` FROM `owned_vehicles` WHERE `plate` = ?', { plate })
    if not raw then return false end
    local ok, props = pcall(json.decode, raw)
    if ok and props and props.model then
        return blacklistedHashes[props.model] == true
    end
    return false
end

---@param source number
---@param plate string
---@return table[] shares { identifier, name, online }
lib.callback.register('ins-garages:getShares', function(source, plate)
    local identifier = GetIdentifier(source)
    if not identifier then return {} end

    plate = Db.NormalizePlate(plate)
    if Db.GetVehicleOwner(plate) ~= identifier then return {} end

    local result = {}
    for _, row in ipairs(Db.GetShares(plate)) do
        local target = Framework.GetPlayerFromIdentifier(row.shared_with)
        result[#result + 1] = {
            identifier = row.shared_with,
            name = target and GetPlayerName(target.source) or row.shared_with,
            online = target ~= nil,
        }
    end
    return result
end)

---@param source number
---@param plate string
---@param targetId number target player's server id
---@return boolean success
---@return string message
lib.callback.register('ins-garages:share', function(source, plate, targetId)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    plate = Db.NormalizePlate(plate)
    if Db.GetVehicleOwner(plate) ~= identifier then
        return false, locale('not_your_vehicle')
    end

    if isBlacklistedPlate(plate) then
        return false, locale('cannot_be_shared')
    end

    local target = Framework.GetPlayerFromId(targetId)
    if not target then
        return false, locale('player_not_found')
    end
    if target.identifier == identifier then
        return false, locale('already_own')
    end

    if Db.IsShared(plate, target.identifier) then
        return false, locale('already_shared')
    end

    Db.AddShare(plate, target.identifier)
    GarageLog('Vehicle shared', ('%s shared `%s` with %s.'):format(
        LogPlayer(source), plate, LogPlayer(target.source)))
    return true, locale('shared_success', GetPlayerName(target.source))
end)

---@param source number
---@param plate string
---@param targetIdentifier string identifier to revoke access from
---@return boolean success
---@return string message
lib.callback.register('ins-garages:unshare', function(source, plate, targetIdentifier)
    local identifier = GetIdentifier(source)
    if not identifier then return false end

    plate = Db.NormalizePlate(plate)
    if Db.GetVehicleOwner(plate) ~= identifier then
        return false, locale('not_your_vehicle')
    end

    Db.RemoveShare(plate, targetIdentifier)
    return true, locale('access_removed')
end)
