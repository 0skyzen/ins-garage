CurrentGarage = nil

---@param spawn vector4
---@return boolean clear true if the spawn point is free enough to drop a vehicle
local function isSpawnClear(spawn)
    local found = lib.getClosestVehicle(vec3(spawn.x, spawn.y, spawn.z), 2.5, false)
    return found == nil or found == 0
end

---@param plate string take a stored vehicle out at the current garage
function TakeOutVehicle(plate)
    if not CurrentGarage then return end

    local spawn = CurrentGarage.spawn
    if not isSpawnClear(spawn) then
        return lib.notify({ type = 'error', description = locale('spawn_blocked') })
    end

    local success, props = lib.callback.await('ins-garages:takeOut', false, plate)
    if not success then
        return lib.notify({ type = 'error', description = props or locale('could_not_take_out') })
    end

    if not lib.requestModel(props.model, 10000) then
        return lib.notify({ type = 'error', description = locale('model_load_failed') })
    end

    local veh = CreateVehicle(props.model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    while not DoesEntityExist(veh) do Wait(0) end

    lib.setVehicleProperties(veh, props)
    SetVehicleNumberPlateText(veh, props.plate)
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(props.model)

    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    lib.notify({ type = 'success', description = locale('vehicle_taken_out') })
end

---Store the vehicle the player is in (or the closest one) back into the garage.
function StoreVehicle()
    local ped = PlayerPedId()
    local seatedIn = GetVehiclePedIsIn(ped, false)
    local veh = seatedIn ~= 0 and seatedIn or lib.getClosestVehicle(GetEntityCoords(ped), 5.0, false)
    if not veh or veh == 0 then
        return lib.notify({ type = 'error', description = locale('no_vehicle_nearby') })
    end

    local plate = GetVehicleNumberPlateText(veh)
    local props = lib.getVehicleProperties(veh)
    local netId = NetworkGetNetworkIdFromEntity(veh)

    local success, msg = lib.callback.await('ins-garages:store', false, plate, props, netId)
    if not success then
        return lib.notify({ type = 'error', description = msg or locale('could_not_store') })
    end

    if seatedIn == veh then
        TaskLeaveVehicle(ped, veh, 0)
        local timeout = GetGameTimer() + 4000
        while GetVehiclePedIsIn(ped, false) == veh and GetGameTimer() < timeout do
            Wait(50)
        end
    end

    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
    lib.notify({ type = 'success', description = msg })
end

---@param garage table
---@return boolean access true when there is no job lock or the player's job matches
local function hasGarageAccess(garage)
    if not garage.job then return true end
    return Framework.GetJobName() == garage.job
end

CreateThread(function()
    for index, garage in ipairs(Config.Garages) do
        garage.index = index

        if garage.blip ~= false then
            local blip = AddBlipForCoord(garage.coords.x, garage.coords.y, garage.coords.z)
            SetBlipSprite(blip, garage.blip and garage.blip.sprite or 357)
            SetBlipColour(blip, garage.blip and garage.blip.color or 3)
            SetBlipScale(blip, garage.blip and garage.blip.scale or 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(garage.label)
            EndTextCommandSetBlipName(blip)
        end

        lib.points.new({
            coords = garage.coords,
            distance = 16.0,
            garage = garage,
            hint = nil,
            nearby = function(self)
                DrawMarker(Config.Marker.type,
                    self.coords.x, self.coords.y, self.coords.z,
                    0, 0, 0, 0, 0, 0,
                    Config.Marker.size.x, Config.Marker.size.y, Config.Marker.size.z,
                    Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                    false, true, 2, false, nil, nil, false)

                local access = hasGarageAccess(self.garage)
                local inVehicle = access and cache.vehicle and self.currentDistance < Config.StoreDistance
                local onFoot = access and not cache.vehicle and self.currentDistance < Config.InteractDistance

                local hint
                if inVehicle then
                    hint = locale('hint_store')
                elseif onFoot then
                    hint = locale('hint_open')
                end

                if hint ~= self.hint then
                    self.hint = hint
                    if hint then
                        CurrentGarage = self.garage
                        lib.showTextUI(hint)
                    else
                        CurrentGarage = nil
                        lib.hideTextUI()
                    end
                end

                if onFoot and IsControlJustReleased(0, Config.OpenKey) then
                    OpenGarageMenu()
                elseif inVehicle and IsControlJustReleased(0, Config.StoreKey) then
                    StoreVehicle()
                end
            end,
            onExit = function(self)
                if self.hint then
                    self.hint = nil
                    CurrentGarage = nil
                    lib.hideTextUI()
                end
            end,
        })
    end
end)
