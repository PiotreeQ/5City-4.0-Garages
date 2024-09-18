local Config = {}

Config.Debug = false

Config.Garages = {
    ['Pillbox'] = {
        coords = vector3(-301.4159, -989.5145, 31.0806),
        size = vector3(10, 10, 10),
        points = {
            vector4(-301.3506, -989.4583, 31.0806, 340.6199),
            vector4(-297.6651, -990.5564, 31.0806, 340.3080),
            vector4(-304.6797, -988.0345, 31.0806, 339.5634)
        }
    }
}

Config.Impounds = {
    ['Pillbox'] = {
        coords = vector3(-305.8080, -975.9277, 31.0806),
        size = vector3(10, 10, 10),
    }
}

return Config