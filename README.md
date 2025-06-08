# 🚘 qb-vehicleshop — Edited by Zoldyck

A customized and enhanced version of the original **QBCore Vehicle Shop**. This version includes stock management integration, anti-exploit limitations, and extended configurability to improve realism and server control.

---

## 🧩 Features

### ✅ Stock Management
This version is compatible with the **`z-cardealer` stock management system**.

> 📌 **Required**: You must install [`z-cardealer`] from our [Tebex store](https://zoldyck-dev.tebex.io) to enable vehicle stock management.

---

### ⚙️ New Configuration Options

Found in `config.lua`, these settings help server owners fine-tune vehicle purchasing logic and prevent abuse:

```lua
Config.Percentage = 0.15                  -- Percentage of vehicle sale that goes to the salesperson’s society account
Config.blocksell = false                  -- Prevent players from selling vehicles to themselves (true = block)
Config.maxduplicated = 200                -- Maximum number of the same vehicle a player can own
Config.max_buy_per_hour = 2               -- Maximum vehicle purchases allowed per player per time period
Config.buy_check_hours = 1                -- Time period (in hours) used to track vehicle purchase limits
Config.DefaultGarage = 'pillboxgarage'    -- Default garage assigned for new vehicles
Config.Log = ''                           -- Discord webhook for logging vehicle sales (leave empty to disable)


**Test Drives:**
* Configurable time
* Returns player once time is up
* Can't take out more than one vehicle

**Financing:**
* Configurable down payment
* Configurable maximum payments
* Configurable commission amount for private dealerships
* Checks for payments due on player join and updates times on player logout or quit

**Shops:**
* Lock to a specific job
* Commission paid to sales person for private dealer
* Create as many as desired with easy polyzone creation
* Vehicle sale amount gets deposited into the cardealer society fund for private dealer

**Planned Updates**
* QB-Phone support to make payments

**Preview header when near a vehicle at the public dealership:**

![image](https://user-images.githubusercontent.com/57848836/138773379-836be2a6-a800-47a4-8037-84d9052a964c.png)

**After pressing the focus key and selecting the preview header (default: LEFT ALT)**

![image](https://user-images.githubusercontent.com/57848836/138770886-15e056db-3e57-43ea-b855-3ef4fd107acf.png)

**Configurable test drive times that automatically return the player**
![20211025160757_1](https://user-images.githubusercontent.com/57848836/138771162-00ee2607-0b56-418b-848c-5d8a009f4acd.jpg)

**Vehicle purchasing**
![20211025160853_1](https://user-images.githubusercontent.com/57848836/138772385-ce16c0e6-baea-4b54-8eff-dbf44c54f568.jpg)

**Private job-based dealership menu (works off closest player)**

![image](https://user-images.githubusercontent.com/57848836/138772120-9513fa09-a22f-4a5f-8afe-6dc7756999f4.png)

**Financing a vehicle with configurable max payment amount and minimum downpayment percentage**
![image](https://user-images.githubusercontent.com/57848836/138771328-0b88078c-9f3d-4754-a4c7-bd5b68dd5129.png)

**Financing preview header**

![image](https://user-images.githubusercontent.com/57848836/138773600-d6f510f8-a476-436d-8211-21e8c920eb6b.png)

**Finance vehicle list**

![image](https://user-images.githubusercontent.com/57848836/138771582-727e7fd4-4837-4320-b79a-479a6268b7ac.png)

**Make a payment or pay off vehicle in full**

![image](https://user-images.githubusercontent.com/57848836/138771627-faed7fcb-73c8-4b77-a33f-fffbb738ab03.png)

### Dependencies:

**[PolyZone](https://github.com/qbcore-framework/PolyZone)**

* You need to create new PolyZones if you want to create a new dealership or move default locations to another area. After you create the new PolyZones, add them to the Config.Shops > [Shape]

* Here's a Wiki on how to create new PolyZone:
https://github.com/mkafrin/PolyZone/wiki/Using-the-creation-script

**[qb-menu](https://github.com/qbcore-framework/qb-menu)**

**[qb-input](https://github.com/qbcore-framework/qb-input)**

```lua
Config = {}
Config.UsingTarget = GetConvar('UseTarget', 'false') == 'true'
Config.Commission = 0.10                              -- Percent that goes to sales person from a full car sale 10%
Config.Percentage = 1.0                              -- Percent that goes to socity person from a full car sale "here is 100%"
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
Config.maxduplicated = 3                             -- maximum number of vehicles a player can have of the same vehicle
Config.max_buy_per_hour = 3                             -- maximum number of vehicles a player can buy per day
Config.buy_check_hours = 24                              -- how many hours to check for max buys
Config.DefaultGarage = 'pillboxgarage'                 -- default garage for vehicles
Config.BlacklistedCategories = {
    ["luxury"] = {             -- blacklist these categories only in "targeted" shop
        "class a",
        "class b",
    },
    ["test"] = {               -- add more categories and shops here
        "emergency",
        "vans",
    }
}

Config.Log = '' -- Discord webhook for logs
Config.TestDriveLog = ''
Config.Shops = {
    ['luxury'] = {
        ['Type'] = 'free-use', -- meaning a real player has to sell the car
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
        ['Job'] = 'none', -- Name of job or none
        ['ShopLabel'] = 'Vehicle Shop',
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
```

# License

    QBCore Framework
    Copyright (C) 2021 Joshua Eger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>
