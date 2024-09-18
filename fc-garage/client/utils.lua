local utils = {}
local Config = lib.require('config')

Citizen.CreateThread(function()
    Wait(1)
    for id, data in pairs(Config.Garages) do
      local box = lib.zones.box({
        coords = data.coords,
        size = data.size,
        rotation = data.rotation or 0.0,
        debug = Config.Debug,
        onEnter = function(self)
          utils.garageId = id
        end,
        onExit = function(self)
          utils.garageId = nil
        end
      })
    end

    for id, data in pairs(Config.Impounds) do
      local box = lib.zones.box({
        coords = data.coords,
        size = data.size,
        rotation = data.rotation or 0.0,
        debug = Config.Debug,
        onEnter = function(self)
          utils.inImpound = true
        end,
        onExit = function(self)
          utils.inImpound = false
        end
      })
    end
end)

utils.findGarage = function()
  local coords = GetEntityCoords(cache.ped)
  local closestCoords, closestDist = nil, nil
  for k, v in pairs(Config.Garages) do
    local distance = #(coords - v.coords)
    if closestDist then
      if distance < closestDist then
        closestCoords = v.coords
        closestDist = distance
      end
    else
      closestCoords = v.coords
      closestDist = distance
    end
  end

  return closestCoords, closestDist
end

utils.getFreeSpawnPoint = function(garageId)
   local garageData = Config.Garages[garageId]
   if not garageId or not garageData then
      return
   end

   local coords = GetEntityCoords(cache.ped)
   local closestSpawn, closestDist = nil, nil
   for i = 1, #garageData.points do
      local point = garageData.points[i]
      local dist = #(vector3(coords.xyz) - vector3(point.xyz))
      if closestDist then
        if dist < closestDist and ESX.Game.IsSpawnPointClear(vector3(point.xyz), 1.5) then
          closestDist = dist
          closestSpawn = i
        end
      else
        if ESX.Game.IsSpawnPointClear(vector3(point.xyz), 1.5) then
          closestDist = dist
          closestSpawn = i
        end
      end
   end

   return closestSpawn
end

utils.SendReactMessage = function(action, data)
    SendNUIMessage({
       action = action,
       data = data
    })
end

utils.toggleNuiFrame = function(shouldShow)
    SetNuiFocus(shouldShow, shouldShow)
    utils.SendReactMessage('setVisible', shouldShow)
end

return utils