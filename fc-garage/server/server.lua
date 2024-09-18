lib.callback.register('fc-garage:fetchVehicles', function(source)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local vehicles = MySQL.query.await('SELECT * FROM owned_vehicles WHERE owner = @id OR co_owner = @id', {['@id'] = xPlayer.identifier})
    return vehicles
end)

lib.callback.register('fc-garage:takeVehicle', function(source, data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local vehicle = MySQL.single.await('SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? AND stored = 1', {xPlayer.identifier, data.plate})
    if vehicle then
        local vehData = json.decode(vehicle.vehicle)
        local entity = CreateVehicle(vehData.model, data.spawn.xyz, data.spawn.w, true, false)
        while not DoesEntityExist(entity) do
            Wait(50)
        end
        
        local netId = NetworkGetNetworkIdFromEntity(entity)
        MySQL.update('UPDATE owned_vehicles SET stored = 0, vehicleid = ? WHERE owner = ? AND plate = ? AND stored = 1', {netId, xPlayer.identifier, data.plate})
        return {vehData = vehData, netId = netId}
    end

    return false
end)

lib.callback.register('fc-garage:parkVehicle', function(source, data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local entity = NetworkGetEntityFromNetworkId(data.netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        xPlayer.showNotification('Ten pojazd nie istnieje')
        return false
    end

    local plate = GetVehicleNumberPlateText(entity)
    data.vehicle.plate = ESX.Math.Trim(data.vehicle.plate)
    if data.vehicle.plate ~= plate then
        xPlayer.showNotification('Nie jesteś właścicielem tego pojazdu')
        return false
    end
    
    local vehData = json.decode(data.vehicle.vehicle)
    local vehicle = MySQL.single.await('SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? AND stored = 0 AND vehicle LIKE "%'..vehData.model..'%"', {xPlayer.identifier, data.vehicle.plate})
    if vehicle then
        DeleteEntity(entity)
        MySQL.update('UPDATE owned_vehicles SET stored = 1, vehicle = ? WHERE owner = ? AND plate = ? AND stored = 0', {json.encode(data.properties), xPlayer.identifier, data.vehicle.plate})
        return true
    end

    xPlayer.showNotification('Nie znaleziono pojazdu')
    return false
end)

lib.callback.register('fc-garage:impoundVehicle', function(source, plate)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    local vehicle = MySQL.single.await('SELECT * FROM owned_vehicles WHERE owner = ? AND plate = ? AND stored = 0', {xPlayer.identifier, plate})
    if vehicle then
        local netId = vehicle.vehicleid
        if netId then
            local success, entity = pcall(NetworkGetEntityFromNetworkId, netId)
            if success and entity and entity ~= 0 and DoesEntityExist(entity) then
                for i = -1, 6, 1 do
                    local seatPed = GetPedInVehicleSeat(entity, i)
                    if seatPed and seatPed ~= 0 then
                        xPlayer.showNotification('Nie udało się odholować pojazdu')
                        goto skip
                        break
                    end
                end

                DeleteEntity(entity)
            end
        end

        MySQL.update('UPDATE owned_vehicles SET stored = 1 WHERE plate = ? AND owner = ?', {plate, xPlayer.identifier})
        return true
    end

    ::skip::
    return false
end)

lib.callback.register('fc-garage:locateVehicle', function(source, data)
    local success, entity = pcall(NetworkGetEntityFromNetworkId, data.netId)
    if success then
        local plate = ESX.Math.Trim(GetVehicleNumberPlateText(entity))
        data.plate = ESX.Math.Trim(data.plate)
        if plate ~= data.plate then
            return false
        end

        local coords = GetEntityCoords(entity)
        return {x = coords.x, y = coords.y}
    end

    return false
end)