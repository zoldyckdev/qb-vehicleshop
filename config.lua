Config = {}
Config.UsingTarget = GetConvar('UseTarget', 'false') == 'true'
Config.Commission = 0.10                              -- Percent that goes to sales person from a full car sale 10%
Config.Percentage = 0.15                              -- Percent that goes to socity person from a full car sale
Config.FinanceCommission = 0.05                       -- Percent that goes to sales person from a finance sale 5%
Config.PaymentWarning = 10                            -- time in minutes that player has to make payment before repo
Config.PaymentInterval = 24                           -- time in hours between payment being due
Config.MinimumDown = 10                               -- minimum percentage allowed down
Config.MaximumPayments = 24                           -- maximum payments allowed
Config.PreventFinanceSelling = false                  -- allow/prevent players from using /transfervehicle if financed
Config.FilterByMake = false                           -- adds a make list before selecting category in shops
Config.SortAlphabetically = true                      -- will sort make, category, and vehicle selection menus alphabetically
Config.HideCategorySelectForOne = true                -- will hide the category selection menu if a shop only sells one category of vehicle or a make has only one category
Config.blocksell = false                              -- allow/prevent players from selling to themselves
Config.maxduplicated = 2                             -- maximum number of vehicles a player can have of the same vehicle
Config.max_buy_per_hour = 3                             -- maximum number of vehicles a player can buy per day
Config.buy_check_hours = 24                              -- how many hours to check for max buys
Config.DefaultGarage = 'pillboxgarage'                 -- default garage for vehicles
Config.BlacklistedCategories = {
    ["luxury"] = {             -- blacklist these categories only in "targeted" shop
        "class a",
        "class b",
    }
--[[     ["test"] = {               -- add more categories and shops here
        "emergency",
        "vans",
    } ]]
}

Config.Log = '' -- Discord webhook for logs
Config.TestDriveLog = ''
Config.Shops = {
    ['luxury'] = {
        ['Type'] = 'managed', -- meaning a real player has to sell the car
        ['Zone'] = {
            ['Shape'] = {
            vector2(-69.166938781738, -1109.6622314453),
            vector2(-22.606502532959, -1118.0949707031),
            vector2(-13.960856437683, -1088.2425537109),
            vector2(-56.031818389893, -1074.7529296875)
            },

            ['minZ'] = 27.602291107178,                                            -- min height of the shop zone
            ['maxZ'] = 28.082290649414,                                            -- max height of the shop zone       
            ['size'] = 2.75    -- size of the vehicles zones
        },
        ['Job'] = 'cardealer', -- Name of job or none
        ['ShopLabel'] = 'Reality CarDealer',
        ['showBlip'] = true,   -- true or false
        ['blipSprite'] = 734,  -- Blip sprite
        ['blipColor'] = 6,     -- Blip color
        ['TestDriveTimeLimit'] = 0.5,
        ['Location'] = vector3(-47.86, -1091.43, 26.84),
        ['ReturnLocation'] = vector3(-1231.46, -349.86, 37.33),
        ['VehicleSpawn'] = vector4(-23.34, -1095.23, 27.32, 340.94),
        ['TestDriveSpawn'] = vector4(-23.34, -1095.23, 27.32, 340.94), -- Spawn location for test drive
        ['FinanceZone'] = vector3(-1256.18, -368.23, 36.91),
        ['ShowroomVehicles'] = {
            [1] = {
                coords = vector4(-49.7, -1083.97, 26.6, 181.94),
                defaultVehicle = 't20',
                chosenVehicle = 't20'
            },
            [2] = {
                coords = vector4(-55.26, -1097.01, 26.6, 295.94),
                defaultVehicle = 'primo',
                chosenVehicle = 'primo'
            },
            [3] = {
                coords = vector4(-47.72, -1091.34, 26.6, 190.93),
                defaultVehicle = 'primo',
                chosenVehicle = 'primo'
            },
            [4] = {
                coords = vector4(-35.92, -1092.68, 26.48, 109.93),
                defaultVehicle = 'primo',
                chosenVehicle = 'primo'
            },
            [5] = {
                coords = vector4(-42.83, -1101.79, 26.48, 289.93),
                defaultVehicle = 'primo',
                chosenVehicle = 'primo'
            },
            [6] = {
                coords = vector4(-42.73, -1101.65, 26.3, 290.72),
                defaultVehicle = 'primo',
                chosenVehicle = 'primo'
            },
        }
    },                         -- Add your next table under this comma
    ['boats'] = {
        ['Type'] = 'free-use', -- no player interaction is required to purchase a vehicle
        ['Zone'] = {
            ['Shape'] = {      --polygon that surrounds the shop
                vector2(-729.39, -1315.84),
                vector2(-766.81, -1360.11),
                vector2(-754.21, -1371.49),
                vector2(-716.94, -1326.88)
            },
            ['minZ'] = 0.0,                                            -- min height of the shop zone
            ['maxZ'] = 5.0,                                            -- max height of the shop zone
            ['size'] = 6.2                                             -- size of the vehicles zones
        },
        ['Job'] = 'none',                                              -- Name of job or none
        ['ShopLabel'] = 'Marina Shop',                                 -- Blip name
        ['showBlip'] = true,                                           -- true or false
        ['blipSprite'] = 410,                                          -- Blip sprite
        ['blipColor'] = 3,                                             -- Blip color
        ['TestDriveTimeLimit'] = 1.5,                                  -- Time in minutes until the vehicle gets deleted
        ['Location'] = vector3(-738.25, -1334.38, 1.6),                -- Blip Location
        ['ReturnLocation'] = vector3(-714.34, -1343.31, 0.0),          -- Location to return vehicle, only enables if the vehicleshop has a job owned
        ['VehicleSpawn'] = vector4(-727.87, -1353.1, -0.17, 137.09),   -- Spawn location when vehicle is bought
        ['TestDriveSpawn'] = vector4(-722.23, -1351.98, 0.14, 135.33), -- Spawn location for test drive
        ['FinanceZone'] = vector3(-729.86, -1319.13, 1.6),
        ['ShowroomVehicles'] = {
            [1] = {
                coords = vector4(-727.05, -1326.59, 0.00, 229.5), -- where the vehicle will spawn on display
                defaultVehicle = 'seashark',                      -- Default display vehicle
                chosenVehicle = 'seashark'                        -- Same as default but is dynamically changed when swapping vehicles
            },
            [2] = {
                coords = vector4(-732.84, -1333.5, -0.50, 229.5),
                defaultVehicle = 'dinghy',
                chosenVehicle = 'dinghy'
            },
            [3] = {
                coords = vector4(-737.84, -1340.83, -0.50, 229.5),
                defaultVehicle = 'speeder',
                chosenVehicle = 'speeder'
            },
            [4] = {
                coords = vector4(-741.53, -1349.7, -2.00, 229.5),
                defaultVehicle = 'marquis',
                chosenVehicle = 'marquis'
            },
        },
    },
}