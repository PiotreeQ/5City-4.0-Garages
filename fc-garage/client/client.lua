local utils = lib.require('client.utils')
local Config = lib.require('config')

local function OpenGarages()
    local vehicles = lib.callback.await('fc-garage:fetchVehicles', false)
    if not vehicles then
        return
    end

    local sortedVehicles = {}
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local vehData = json.decode(vehicle.vehicle)
        local vehModel = GetDisplayNameFromVehicleModel(vehData.model)
        local vehLabel = GetLabelText(vehModel)
        sortedVehicles[i] = {
            name = vehLabel ~= 'NULL' and vehLabel or vehModel,
            plate = vehicle.plate,
            vin = vehicle.vin or 'BRAK',
            vehicle = vehicle.vehicle,
            vehicleid = vehicle.vehicleid,
            engine = vehData.engineHealth and math.floor(vehData.engineHealth / 10) or 100,
            body = vehData.bodyHealth and math.floor(vehData.bodyHealth / 10) or 100,
            fuel = vehData.fuelLevel and math.floor(vehData.fuelLevel) or 100,
            model = string.lower(vehModel),
            status = vehicle.stored
        }
    end
    utils.SendReactMessage('loadVehicles', {vehicles = sortedVehicles, inImpound = utils.inImpound})
    utils.toggleNuiFrame(true)
end

Citizen.CreateThread(function()
    lib.addRadialItem({
        id = 'garages',
        icon = 'car',
        label = 'Garaż',
        onSelect = OpenGarages
    })
end)

exports('OpenGarages', OpenGarages)
RegisterNetEvent('fc-garage:openGarages', OpenGarages)
RegisterCommand('test_garage', OpenGarages)

RegisterNUICallback('locateGarage', function(_, cb)
    local coords, dist = utils.findGarage()
    if not coords then
        return
    end
    
    SetNewWaypoint(coords.x, coords.y)
    ESX.ShowNotification(('Oznaczono najbliższy parking który znajduje się od ciebie %s metrów'):format(math.floor(dist)))
    cb({})
end)

RegisterNUICallback('takeVehicle', function(data, cb)
    if not utils.garageId then
        ESX.ShowNotification('Nie jesteś w pobliżu garażu')
        cb(false)
        return
    end

    local spawnId = utils.getFreeSpawnPoint(utils.garageId)
    if not spawnId then
        ESX.ShowNotification('Brak wolnego miejsca parkingowego')
        cb(false)
        return
    end

    local spawn = Config.Garages[utils.garageId].points[spawnId]
    local result = lib.callback.await('fc-garage:takeVehicle', false, {plate = ESX.Math.Trim(data.plate), spawn = spawn})
    if result then
        local entity = NetworkGetEntityFromNetworkId(result.netId)
        lib.setVehicleProperties(entity, result.vehData)
    end
    cb(result)
end)

RegisterNUICallback('parkVehicle', function(data, cb)
    local vehicle = cache.vehicle
    if not vehicle or vehicle == 0 then
        local coords = GetEntityCoords(cache.ped)
        vehicle = lib.getClosestVehicle(coords, 7.5, true)
    end

    if not vehicle or vehicle == 0 then
        return ESX.ShowNotification('Nie ma żadnego pojazdu w pobliżu')
    end
    
    local result = lib.callback.await('fc-garage:parkVehicle', false, {
        vehicle = data,
        netId = NetworkGetNetworkIdFromEntity(vehicle),
        properties = lib.getVehicleProperties(vehicle)
    })
    cb(result)
end)

local antiSpam = GetGameTimer()
RegisterNUICallback('locateVehicle', function(data, cb)
    if antiSpam > GetGameTimer() then
        return ESX.ShowNotification('Odczekaj chwile')
    end

    antiSpam = GetGameTimer() + 5000
    local result = lib.callback.await('fc-garage:locateVehicle', false, {netId = data.vehicleid, plate = data.plate})
    if result then
        ESX.ShowNotification('Oznaczono pojazd na mapie')
        SetNewWaypoint(result.x, result.y)
    else
        ESX.ShowNotification('Nie udało się zlokalizować pojazdu')
    end
    cb({})
end)

RegisterNUICallback('impoundVehicle', function(data, cb)
    local result = lib.callback.await('fc-garage:impoundVehicle', false, ESX.Math.Trim(data.plate))
    cb(result)
end)

RegisterNUICallback('hideFrame', function(_, cb)
    utils.toggleNuiFrame(false)
    cb({})
end)