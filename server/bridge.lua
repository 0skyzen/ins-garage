---@param res string resource name
---@return boolean present true if the resource exists (even if not started yet)
local function present(res)
    local state = GetResourceState(res)
    return state ~= 'missing' and state ~= 'unknown'
end

local name = Config.Framework
if name == 'auto' then
    if present('es_extended') then
        name = 'esx'
    elseif present('qb-core') then
        name = 'qb'
    end
end

Framework = { name = name }

if name == 'auto' then
    print("^1[ins-garages]^7 No framework found. Install ESX or QBCore, or set Config.Framework manually.")
end

local ESX, QBCore

---@return table? core framework object, fetched lazily on first use
local function core()
    if name == 'esx' then
        ESX = ESX or exports['es_extended']:getSharedObject()
        return ESX
    elseif name == 'qb' then
        QBCore = QBCore or exports['qb-core']:GetCoreObject()
        return QBCore
    end
end

---@param player table? raw framework player object
---@return table? player normalized as { source, identifier, job }
local function wrap(player)
    if not player then return nil end
    if name == 'esx' then
        local job = player.getJob and player.getJob() or player.job
        return { source = player.source, identifier = player.identifier, job = job and job.name or nil }
    else
        local data = player.PlayerData
        return { source = data.source, identifier = data.citizenid, job = data.job and data.job.name or nil }
    end
end

---@param source number
---@return table? player { source, identifier, job }
function Framework.GetPlayerFromId(source)
    local fw = core()
    if not fw then return nil end
    if name == 'esx' then
        return wrap(fw.GetPlayerFromId(source))
    end
    return wrap(fw.Functions.GetPlayer(source))
end

---@param identifier string ESX identifier or QB citizenid
---@return table? player { source, identifier, job }
function Framework.GetPlayerFromIdentifier(identifier)
    local fw = core()
    if not fw then return nil end
    if name == 'esx' then
        return wrap(fw.GetPlayerFromIdentifier(identifier))
    end
    return wrap(fw.Functions.GetPlayerByCitizenId(identifier))
end

---@param source number
---@param amount number
---@return boolean success false when the player cannot pay
function Framework.RemoveMoney(source, amount)
    if amount <= 0 then return true end
    local fw = core()
    if not fw then return false end
    if name == 'esx' then
        local x = fw.GetPlayerFromId(source)
        if not x then return false end
        if x.getMoney() < amount then return false end
        x.removeMoney(amount)
        return true
    else
        local p = fw.Functions.GetPlayer(source)
        if not p then return false end
        return p.Functions.RemoveMoney('cash', amount, 'ins-garages-recover') == true
    end
end

---@param source number
---@return string? identifier
---@return string? job
function GetPlayerData(source)
    local player = Framework.GetPlayerFromId(source)
    if not player then return nil, nil end
    return player.identifier, player.job
end

---@param source number
---@return string? identifier
function GetIdentifier(source)
    return (GetPlayerData(source))
end
