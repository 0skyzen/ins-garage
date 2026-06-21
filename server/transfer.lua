local jobBlacklist = {}
for _, name in ipairs(Config.JobTransferBlacklist) do
    jobBlacklist[name:lower()] = true
end

---@param source number
---@param plate string
---@return boolean ok true when the player is the personal owner of a stored vehicle
---@return string result error message on failure, or the normalized plate on success
local function canTransfer(source, plate)
    local identifier = GetIdentifier(source)
    if not identifier then return false, locale('player_not_found') end

    plate = Db.NormalizePlate(plate)
    if Db.GetVehicleOwner(plate) ~= identifier then
        return false, locale('not_your_vehicle')
    end
    if not Db.IsStored(plate) then
        return false, locale('store_before_transfer')
    end
    return true, plate
end

---@param source number
---@param plate string
---@param targetId number target player's server id
---@return boolean success
---@return string message
lib.callback.register('ins-garages:transferToPlayer', function(source, plate, targetId)
    local ok, result = canTransfer(source, plate)
    if not ok then return false, result end
    plate = result

    local target = Framework.GetPlayerFromId(targetId)
    if not target then
        return false, locale('player_not_found')
    end
    if target.identifier == GetIdentifier(source) then
        return false, locale('already_own')
    end

    Db.TransferVehicle(plate, target.identifier, nil)
    GarageLog('Vehicle transferred', ('%s transferred `%s` to %s.'):format(
        LogPlayer(source), plate, LogPlayer(target.source)))
    TriggerClientEvent('ox_lib:notify', target.source, {
        type = 'inform',
        description = locale('transfer_received'),
    })
    return true, locale('transfer_success', GetPlayerName(target.source))
end)

---@param source number
---@param plate string
---@return boolean success
---@return string message
lib.callback.register('ins-garages:transferToJob', function(source, plate)
    local ok, result = canTransfer(source, plate)
    if not ok then return false, result end
    plate = result

    local _, job = GetPlayerData(source)
    if not job or jobBlacklist[job:lower()] then
        return false, locale('job_blacklisted')
    end

    Db.TransferVehicle(plate, job, job)
    GarageLog('Vehicle transferred to faction', ('%s transferred `%s` to job `%s`.'):format(
        LogPlayer(source), plate, job))
    return true, locale('transfer_success', job)
end)
