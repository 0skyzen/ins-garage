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

---@return table? job the player's current job table
local function getJob()
    local fw = core()
    if not fw then return nil end
    if name == 'esx' then
        local data = fw.GetPlayerData()
        return data and data.job
    elseif name == 'qb' then
        local data = fw.Functions.GetPlayerData()
        return data and data.job
    end
end

---@return string? label the player's current job label (or name)
function Framework.GetJobLabel()
    local job = getJob()
    return job and (job.label ~= '' and job.label or job.name) or nil
end

---@return string? name the player's current job name
function Framework.GetJobName()
    local job = getJob()
    return job and job.name or nil
end
