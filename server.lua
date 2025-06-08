-- Variables
local QBCore = exports['qb-core']:GetCoreObject()
local financetimer = {}

local vehicleTypes = { -- https://docs.fivem.net/natives/?_0xA273060E
    motorcycles = 'bike',
    boats = 'boat',
    helicopters = 'heli',
    planes = 'plane',
    submarines = 'submarine',
    trailer = 'trailer',
    train = 'train'
}

local function GetVehicleTypeByModel(model)
    local vehicleData = QBCore.Shared.Vehicles[model]
    if not vehicleData then return 'automobile' end
    local category = vehicleData.category
    local vehicleType = vehicleTypes[category]
    return vehicleType or 'automobile'
end

QBCore.Functions.CreateCallback('qb-vehicleshop:server:spawnvehicle', function(source, cb, plate, vehicle, coords)
    local vehType = QBCore.Shared.Vehicles[vehicle] and QBCore.Shared.Vehicles[vehicle].type or GetVehicleTypeByModel(vehicle)
    local veh = CreateVehicleServerSetter(GetHashKey(vehicle), vehType, coords.x, coords.y, coords.z, coords.w)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    SetVehicleNumberPlateText(veh, plate)
    local vehProps = {}
    local result = MySQL.rawExecute.await('SELECT mods FROM player_vehicles WHERE plate = ?', { plate })
    if result and result[1] then vehProps = json.decode(result[1].mods) end
    cb(netId, vehProps, plate)
end)

-- Handlers
-- Store game time for player when they load
RegisterNetEvent('qb-vehicleshop:server:addPlayer', function(citizenid)
    financetimer[citizenid] = os.time()
end)

-- Deduct stored game time from player on logout
RegisterNetEvent('qb-vehicleshop:server:removePlayer', function(citizenid)
    if financetimer[citizenid] then
        local playTime = financetimer[citizenid]
        local financetime = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', { citizenid })
        for _, v in pairs(financetime) do
            if v.balance >= 1 then
                local newTime = (v.financetime - ((os.time() - playTime) / 60))
                if newTime < 0 then newTime = 0 end
                MySQL.update('UPDATE player_vehicles SET financetime = ? WHERE plate = ?', { math.ceil(newTime), v.plate })
            end
        end
    end
    financetimer[citizenid] = nil
end)

-- Deduct stored game time from player on quit because we can't get citizenid
AddEventHandler('playerDropped', function()
    local src = source
    local license
    for _, v in pairs(GetPlayerIdentifiers(src)) do
        if string.sub(v, 1, string.len('license:')) == 'license:' then
            license = v
        end
    end
    if license then
        local vehicles = MySQL.query.await('SELECT * FROM player_vehicles WHERE license = ?', { license })
        if vehicles then
            for _, v in pairs(vehicles) do
                local playTime = financetimer[v.citizenid]
                if v.balance >= 1 and playTime then
                    local newTime = (v.financetime - ((os.time() - playTime) / 60))
                    if newTime < 0 then newTime = 0 end
                    MySQL.update('UPDATE player_vehicles SET financetime = ? WHERE plate = ?', { math.ceil(newTime), v.plate })
                end
            end
            if vehicles[1] and financetimer[vehicles[1].citizenid] then financetimer[vehicles[1].citizenid] = nil end
        end
    end
end)

-- Functions
local function round(x)
    return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

local function calculateFinance(vehiclePrice, downPayment, paymentamount)
    local balance = vehiclePrice - downPayment
    local vehPaymentAmount = balance / paymentamount
    return round(balance), round(vehPaymentAmount)
end

local function calculateNewFinance(paymentAmount, vehData)
    local newBalance = tonumber(vehData.balance - paymentAmount)
    local minusPayment = vehData.paymentsLeft - 1
    local newPaymentsLeft = newBalance / minusPayment
    local newPayment = newBalance / newPaymentsLeft
    return round(newBalance), round(newPayment), newPaymentsLeft
end

local function GeneratePlate()
    local plate = QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(2)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    if result then
        return GeneratePlate()
    else
        return plate:upper()
    end
end

local function comma_value(amount)
    local formatted = amount
    local k
    while true do
        formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
        if (k == 0) then
            break
        end
    end
    return formatted
end

-- Callbacks
QBCore.Functions.CreateCallback('qb-vehicleshop:server:getVehicles', function(source, cb)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if player then
        local vehicles = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', { player.PlayerData.citizenid })
        if vehicles[1] then
            cb(vehicles)
        end
    end
end)

-- Events

-- Brute force vehicle deletion
RegisterNetEvent('qb-vehicleshop:server:deleteVehicle', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    DeleteEntity(vehicle)
end)

-- Sync vehicle for other players
RegisterNetEvent('qb-vehicleshop:server:swapVehicle', function(data)
    local src = source
    TriggerClientEvent('qb-vehicleshop:client:swapVehicle', -1, data)
    Wait(1500)                                                -- let new car spawn
    TriggerClientEvent('qb-vehicleshop:client:homeMenu', src) -- reopen main menu
end)

local function sendDiscordLog(webhook, title, description, color)
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        embeds = {{
            title = title,
            description = description,
            color = color,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer = {
                text = "QBCore Vehicle Shop",
                icon_url = ""
            }
        }},
        username = "Vehicle Shop",
        avatar_url = "" 
    }), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('qb-vehicleshop:server:customTestDrive', function(vehicle, playerid)
    local src = source
    local target = tonumber(playerid)
    
    local srcPlayer = QBCore.Functions.GetPlayer(src)
    local targetPlayer = QBCore.Functions.GetPlayer(target)
    
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.Invalid_ID'), 'error')
        return
    end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) < 3 then
        TriggerClientEvent('qb-vehicleshop:client:customTestDrive', target, vehicle)
        local srcDiscordRaw = QBCore.Functions.GetIdentifier(src, "discord") or "discord:N/A"
        local targetDiscordRaw = QBCore.Functions.GetIdentifier(target, "discord") or "discord:N/A"
        local function cleanDiscordId(discordId)
            return discordId:gsub("discord:", "")
        end
        local srcDiscordId = cleanDiscordId(srcDiscordRaw)
        local targetDiscordId = cleanDiscordId(targetDiscordRaw)
        local srcMention = srcDiscordId ~= "N/A" and ("<@" .. srcDiscordId .. ">") or "Unknown"
        local targetMention = targetDiscordId ~= "N/A" and ("<@" .. targetDiscordId .. ">") or "Unknown"

        local vehicleName = "Unknown Vehicle"
        if vehicle then
            if type(vehicle) == "table" then
                vehicleName = vehicle.name or vehicle.model or "Unknown Vehicle"
            elseif type(vehicle) == "string" then
                vehicleName = vehicle
            end
        end

        local testDriveTime = os.date("%Y-%m-%d %H:%M:%S")

        local description = 
            "**Test Drive Started**\n" ..
            "**Time:** " .. testDriveTime .. "\n" ..
            "**Source Player:** " .. srcPlayer.PlayerData.charinfo.firstname .. " " .. srcPlayer.PlayerData.charinfo.lastname .. 
            " (ID: " .. src .. ") " .. srcMention .. "\n" ..
            "**Target Player:** " .. targetPlayer.PlayerData.charinfo.firstname .. " " .. targetPlayer.PlayerData.charinfo.lastname .. 
            " (ID: " .. target .. ") " .. targetMention .. "\n" ..
            "**Vehicle:** " .. vehicleName
        sendDiscordLog(Config.TestDriveLog, "Vehicle Shop - Test Drive", description, 3447003)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.playertoofar'), 'error')
    end
end)
-- Make a finance payment
RegisterNetEvent('qb-vehicleshop:server:financePayment', function(paymentAmount, vehData)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local cash = player.PlayerData.money['cash']
    local bank = player.PlayerData.money['bank']
    local plate = vehData.vehiclePlate
    paymentAmount = tonumber(paymentAmount)
    local minPayment = tonumber(vehData.paymentAmount)
    local timer = (Config.PaymentInterval * 60)
    local newBalance, newPaymentsLeft, newPayment = calculateNewFinance(paymentAmount, vehData)
    if newBalance > 0 then
        if player and paymentAmount >= minPayment then
            if cash >= paymentAmount then
                player.Functions.RemoveMoney('cash', paymentAmount, 'financed vehicle')
                MySQL.update('UPDATE player_vehicles SET balance = ?, paymentamount = ?, paymentsleft = ?, financetime = ? WHERE plate = ?', { newBalance, newPayment, newPaymentsLeft, timer, plate })
            elseif bank >= paymentAmount then
                player.Functions.RemoveMoney('bank', paymentAmount, 'financed vehicle')
                MySQL.update('UPDATE player_vehicles SET balance = ?, paymentamount = ?, paymentsleft = ?, financetime = ? WHERE plate = ?', { newBalance, newPayment, newPaymentsLeft, timer, plate })
            else
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.minimumallowed') .. comma_value(minPayment), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.overpaid'), 'error')
    end
end)


-- Pay off vehice in full
RegisterNetEvent('qb-vehicleshop:server:financePaymentFull', function(data)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local cash = player.PlayerData.money['cash']
    local bank = player.PlayerData.money['bank']
    local vehBalance = data.vehBalance
    local vehPlate = data.vehPlate
    if player and vehBalance ~= 0 then
        if cash >= vehBalance then
            player.Functions.RemoveMoney('cash', vehBalance, 'paid off vehicle')
            MySQL.update('UPDATE player_vehicles SET balance = ?, paymentamount = ?, paymentsleft = ?, financetime = ? WHERE plate = ?', { 0, 0, 0, 0, vehPlate })
        elseif bank >= vehBalance then
            player.Functions.RemoveMoney('bank', vehBalance, 'paid off vehicle')
            MySQL.update('UPDATE player_vehicles SET balance = ?, paymentamount = ?, paymentsleft = ?, financetime = ? WHERE plate = ?', { 0, 0, 0, 0, vehPlate })
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.alreadypaid'), 'error')
    end
end)

-- Buy public vehicle outright
RegisterNetEvent('qb-vehicleshop:server:buyShowroomVehicle', function(vehicleData)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local vehicle = vehicleData.buyVehicle
    local cid = player.PlayerData.citizenid
    local cash = player.PlayerData.money['cash']
    local bank = player.PlayerData.money['bank']
    local license = player.PlayerData.license
    local discordId = QBCore.Functions.GetIdentifier(src, 'discord')
    
    local maxBuysPerHour = Config.max_buy_per_hour or 5
    local checkWindow = Config.buy_check_hours or 1

    local sellCount = MySQL.scalar.await(
        'SELECT COUNT(*) FROM z_dealer_logs WHERE buyer_name = ? AND `date` >= NOW() - INTERVAL ? HOUR',
        { playerName, checkWindow }
    )

    if sellCount >= maxBuysPerHour then
        TriggerClientEvent('QBCore:Notify', src, 'You have reached the maximum number of purchases in the last ' .. checkWindow .. ' hour(s)', 'error')
        return
    end

    local modelCount = MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ? AND vehicle = ?', {
        cid,
        vehicle
    })

    if modelCount >= Config.maxduplicated then
        TriggerClientEvent('QBCore:Notify', src, 'You can only own ' .. Config.maxduplicated .. ' of this vehicle', 'error')
        return
    end  

    local vehicleInfo = QBCore.Shared.Vehicles[vehicle]
    if not vehicleInfo then
        TriggerClientEvent('QBCore:Notify', src, "Vehicle data not found", "error")
        return
    end

    local vehiclePrice = vehicleInfo.price
    if not vehiclePrice then
        TriggerClientEvent('QBCore:Notify', src, "Vehicle price not found", "error")
        return
    end

    local stock = MySQL.single.await('SELECT stock FROM vehicle_stock WHERE vehicle = ?', { vehicle })
    if not stock or stock.stock <= 0 then
        TriggerClientEvent('QBCore:Notify', src, "This vehicle is out of stock", 'error')
        return
    end

    local function comma_value(n)
        local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
        return left .. (num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
    end

    local function logSale(paymentMethod, plate)
        local vehicleData = QBCore.Shared.Vehicles[vehicle]
        local playerDiscord = discordId and string.gsub(discordId, "discord:", "") or "Unknown"
        local logData = {
            username = '🚗 Vehicle Sales Log',
            embeds = {{
                title = '**🚘 Vehicle Sold - Transaction Details**',
                color = 16760576,
                description = "**A new vehicle sale has been completed! (Free Use)** 🎉",
                fields = {
                    {
                        name = '👤 **Seller Information**',
                        value = "free-use seller",
                        inline = false
                    },
                    {
                        name = '🛒 **Buyer Information**',
                        value = string.format("**Name:** %s\n**CID:** %s\n**License:** %s\n**Discord:** <@%s>",
                            playerName, cid, license, playerDiscord),
                        inline = false
                    },
                    {
                        name = '🚗 **Vehicle Information**',
                        value = string.format("**Model:** %s\n**Brand:** %s\n**Category:** %s\n**Plate:** %s", 
                            vehicle, vehicleData.brand or "Unknown", vehicleData.category or "Unknown", plate),
                        inline = false
                    },
                    {
                        name = '💰 **Price & Payment**',
                        value = string.format("💵 **Price:** $%s\n💳 **Paid With:** %s", comma_value(vehiclePrice), paymentMethod),
                        inline = true
                    },
                    {
                        name = '💸 **Commission Earned**',
                        value = "$0", -- No commission in free-use
                        inline = true
                    }
                },
                footer = {
                    text = "🔹 Transaction Date: " .. os.date("%Y-%m-%d %H:%M:%S")
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        PerformHttpRequest(Config.Log, function() end, 'POST', json.encode(logData), { ['Content-Type'] = 'application/json' })
    end

    local function completePurchase(paymentMethod)
        local plate = GeneratePlate()

        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            Config.DefaultGarage,
            0
        })

        MySQL.update('UPDATE vehicle_stock SET stock = stock - 1 WHERE vehicle = ?', { vehicle })

        MySQL.insert('INSERT INTO z_dealer_logs (dealer_name, buyer_name, vehicle, color, payment_method, amount, status) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            "free-use seller",
            playerName,
            vehicle,
            plate,
            paymentMethod,
            vehiclePrice,
            'success'
        })

        logSale(paymentMethod, plate)
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.purchased'), 'success')
        TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', src, vehicle, plate)
        player.Functions.RemoveMoney(paymentMethod, vehiclePrice, 'vehicle-bought-in-showroom')
    end

    if cash >= vehiclePrice then
        completePurchase('cash')
    elseif bank >= vehiclePrice then
        completePurchase('bank')
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    end
end)


-- Finance public vehicle
RegisterNetEvent('qb-vehicleshop:server:financeVehicle', function(downPayment, paymentAmount, vehicle)
    local src = source
    downPayment = tonumber(downPayment)
    paymentAmount = tonumber(paymentAmount)
    local pData = QBCore.Functions.GetPlayer(src)
    local cid = pData.PlayerData.citizenid
    local cash = pData.PlayerData.money['cash']
    local bank = pData.PlayerData.money['bank']
    local vehiclePrice = QBCore.Shared.Vehicles[vehicle]['price']
    local timer = (Config.PaymentInterval * 60)
    local minDown = tonumber(round((Config.MinimumDown / 100) * vehiclePrice))
    if downPayment > vehiclePrice then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notworth'), 'error') end
    if downPayment < minDown then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.downtoosmall'), 'error') end
    if paymentAmount > Config.MaximumPayments then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.exceededmax'), 'error') end
    local plate = GeneratePlate()
    local balance, vehPaymentAmount = calculateFinance(vehiclePrice, downPayment, paymentAmount)
    if cash >= downPayment then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, balance, paymentamount, paymentsleft, financetime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            pData.PlayerData.license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            Config.DefaultGarage,
            0,
            balance,
            vehPaymentAmount,
            paymentAmount,
            timer
        })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.purchased'), 'success')
        TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', src, vehicle, plate)
        pData.Functions.RemoveMoney('cash', downPayment, 'vehicle-bought-in-showroom')
    elseif bank >= downPayment then
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, balance, paymentamount, paymentsleft, financetime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            pData.PlayerData.license,
            cid,
            vehicle,
            GetHashKey(vehicle),
            '{}',
            plate,
            Config.DefaultGarage,
            0,
            balance,
            vehPaymentAmount,
            paymentAmount,
            timer
        })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.purchased'), 'success')
        TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', src, vehicle, plate)
        pData.Functions.RemoveMoney('bank', downPayment, 'vehicle-bought-in-showroom')
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
    end
end)

-- Get vehicle stock

QBCore.Functions.CreateCallback('qb-vehicleshop:server:GetVehicleStock', function(source, cb, vehicle)
    local result = MySQL.scalar.await('SELECT stock FROM vehicle_stock WHERE vehicle = ?', {vehicle})
    cb(result or 0)
end)

-- Sell vehicle to customer
RegisterNetEvent('qb-vehicleshop:server:sellShowroomVehicle', function(data, playerid)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local playerid = tonumber(playerid)
    local target = QBCore.Functions.GetPlayer(playerid)
    local playerdiscordid = QBCore.Functions.GetIdentifier(src, 'discord')
    local targetdiscordid = QBCore.Functions.GetIdentifier(playerid, 'discord')
    local targetname = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
    print(targetname)
    local maxBuysPerHour = Config.max_buy_per_hour  or 5-- e.g., 3
    local checkWindow = Config.buy_check_hours or 1 
    local sellcount = MySQL.scalar.await(
        'SELECT COUNT(*) FROM z_dealer_logs WHERE buyer_name = ? AND `date` >= NOW() - INTERVAL ? HOUR',
        { targetname, checkWindow }
    )
    if sellcount >= maxBuysPerHour then
        TriggerClientEvent('QBCore:Notify', src, 'You have reached the maximum number of purchases in the last ' .. checkWindow .. ' hour(s)', 'error')
        return
    end    
    if not target then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.Invalid_ID'), 'error')
        return
    end
    if Config.blocksell then 
        if player.PlayerData.citizenid == target.PlayerData.citizenid then
            TriggerClientEvent('QBCore:Notify', src, "You can't sell it to yourself", 'error')
            return
        end
    end
    local modelCount = MySQL.scalar.await('SELECT COUNT(*) FROM player_vehicles WHERE citizenid = ? AND vehicle = ?', {
        target.PlayerData.citizenid,
        vehicle
    })
    if modelCount >= Config.maxduplicated then
        TriggerClientEvent('QBCore:Notify', src, 'You can only have ' .. Config.maxduplicated .. ' of this vehicle', 'error')
        TriggerClientEvent('QBCore:Notify', target.PlayerData.source, 'You can only have ' .. Config.maxduplicated .. ' of this vehicle', 'error')
        return
    end
    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target.PlayerData.source))) < 3 then
        local cid = target.PlayerData.citizenid
        local paymentmethod = ''
        local cash = target.PlayerData.money['cash']
        local bank = target.PlayerData.money['bank']
        local vehicle = data
        local vehiclePrice = QBCore.Shared.Vehicles[vehicle]['price']
        local commission = round(vehiclePrice * Config.Commission)
        local plate = GeneratePlate()
        local vehicle = data.vehicle or data
        if type(vehicle) == "table" and vehicle.vehicle then
            vehicle = vehicle.vehicle
        end
        local vehicleData = QBCore.Shared.Vehicles[vehicle]
        if not vehicleData then
            TriggerClientEvent('QBCore:Notify', src, "Vehicle data not found", "error")
            return
        end
        local result = MySQL.single.await('SELECT stock FROM vehicle_stock WHERE vehicle = ?', { vehicle })
        if not result or result.stock <= 0 then
            TriggerClientEvent('QBCore:Notify', src, "This vehicle is out of stock", 'error')
            return
        end
        local vehiclePrice = vehicleData.price
        local commission = round(vehiclePrice * Config.Commission)
        local plate = GeneratePlate()
        local paymentmethod = ''
        local function selllog(player, target, vehicle, plate, vehiclePrice, paymentmethed, playerdiscordid, targetdiscordid)
            local vehicleData = QBCore.Shared.Vehicles[vehicle]
            local brand = vehicleData.brand or "Unknown"
            local category = vehicleData.category or "Unknown"
            -- Remove discord: prefix and format Discord IDs
            local playerDiscord = playerdiscordid and string.gsub(playerdiscordid, "discord:", "") or "Unknown"
            local targetDiscord = targetdiscordid and string.gsub(targetdiscordid, "discord:", "") or "Unknown"
            local logData = {
                username = '🚗 Vehicle Sales Log',
                embeds = {{
                    title = '**🚘 Vehicle Sold - Transaction Details**',
                    color = 16760576,
                    description = "**A new vehicle sale has been completed!** 🎉",
                    fields = {
                        {
                            name = '👤 **Seller Information**',
                            value = string.format("**Name:** %s %s\n**CID:** %s\n**License:** %s\n**Discord:** <@%s>",
                                player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname,
                                player.PlayerData.citizenid, player.PlayerData.license, playerDiscord),
                            inline = false
                        },
                        {
                            name = '🛒 **Buyer Information**',
                            value = string.format("**Name:** %s %s\n**CID:** %s\n**License:** %s\n**Discord:** <@%s>",
                                target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname,
                                target.PlayerData.citizenid, target.PlayerData.license, targetDiscord),
                            inline = false
                        },
                        {
                            name = '🚗 **Vehicle Information**',
                            value = string.format("**Model:** %s\n**Brand:** %s\n**Category:** %s\n**Plate:** %s", 
                                vehicle, brand, category, plate),
                            inline = false
                        },
                        {
                            name = '💰 **Price & Payment**',
                            value = string.format("💵 **Price:** $%s\n💳 **Paid With:** %s", comma_value(vehiclePrice),
                                paymentmethod == 'cash' and 'Cash' or 'Bank'),
                            inline = true
                        },
                        {
                            name = '💸 **Commission Earned**',
                            value = string.format("$%s", comma_value(commission)),
                            inline = true
                        }
                    },
                    footer = {
                        text = "🔹 Transaction Date: " .. os.date("%Y-%m-%d %H:%M:%S")
                    },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            }
            PerformHttpRequest(Config.Log, function(err, text, headers) end, 'POST', json.encode(logData), { ['Content-Type'] = 'application/json' })
        end
        if cash >= tonumber(vehiclePrice) then
            paymentmethod = 'cash'
            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
                target.PlayerData.license,
                cid,
                vehicle,
                GetHashKey(vehicle),
                '{}',
                plate,
                Config.DefaultGarage,
                0
            })
            MySQL.update('UPDATE vehicle_stock SET stock = stock - 1 WHERE vehicle = ?', { vehicle })
            MySQL.insert('INSERT INTO z_dealer_logs (dealer_name, buyer_name, vehicle, color, payment_method, amount, status) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname,
                vehicle,
                plate,
                paymentmethod,
                vehiclePrice,
                'success'
            })
            TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', target.PlayerData.source, vehicle, plate)
            target.Functions.RemoveMoney('cash', vehiclePrice, 'vehicle-bought-in-showroom')
            player.Functions.AddMoney('bank', commission, 'vehicle sale commission')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.earned_commission', { amount = comma_value(commission) }), 'success')
            exports['qb-banking']:AddMoney(player.PlayerData.job.name, vehiclePrice * Config.Percentage, 'Vehicle sale')
            TriggerClientEvent('QBCore:Notify', target.PlayerData.source, Lang:t('success.purchased'), 'success')
            selllog(player, target, vehicle, plate, vehiclePrice, paymentmethed, playerdiscordid, targetdiscordid)
        elseif bank >= tonumber(vehiclePrice) then
            paymentmethod = 'bank'
            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
                target.PlayerData.license,
                cid,
                vehicle,
                GetHashKey(vehicle),
                '{}',
                plate,
                Config.DefaultGarage,
                0
            })
            MySQL.update('UPDATE vehicle_stock SET stock = stock - 1 WHERE vehicle = ?', { vehicle })
            MySQL.insert('INSERT INTO z_dealer_logs (dealer_name, buyer_name, vehicle, color, payment_method, amount, status) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname,
                vehicle,
                plate,
                paymentmethod,
                vehiclePrice,
                'success'
            })
            selllog(player, target, vehicle, plate, vehiclePrice, paymentmethed, playerdiscordid, targetdiscordid)
            TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', target.PlayerData.source, vehicle, plate)
            target.Functions.RemoveMoney('bank', vehiclePrice, 'vehicle-bought-in-showroom')
            player.Functions.AddMoney('bank', commission, 'vehicle sale commission')
            exports['qb-banking']:AddMoney(player.PlayerData.job.name, vehiclePrice * Config.Percentage, 'Vehicle sale')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.earned_commission', { amount = comma_value(commission) }), 'success')
            TriggerClientEvent('QBCore:Notify', target.PlayerData.source, Lang:t('success.purchased'), 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.playertoofar'), 'error')
    end
end)

-- Finance vehicle to customer
RegisterNetEvent('qb-vehicleshop:server:sellfinanceVehicle', function(downPayment, paymentAmount, vehicle, playerid)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local target = QBCore.Functions.GetPlayer(tonumber(playerid))

    if not target then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.Invalid_ID'), 'error')
        return
    end

    if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target.PlayerData.source))) < 3 then
        downPayment = tonumber(downPayment)
        paymentAmount = tonumber(paymentAmount)
        local cid = target.PlayerData.citizenid
        local cash = target.PlayerData.money['cash']
        local bank = target.PlayerData.money['bank']
        local vehiclePrice = QBCore.Shared.Vehicles[vehicle]['price']
        local timer = (Config.PaymentInterval * 60)
        local minDown = tonumber(round((Config.MinimumDown / 100) * vehiclePrice))
        if downPayment > vehiclePrice then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notworth'), 'error') end
        if downPayment < minDown then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.downtoosmall'), 'error') end
        if paymentAmount > Config.MaximumPayments then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.exceededmax'), 'error') end
        local commission = round(vehiclePrice * Config.Commission)
        local plate = GeneratePlate()
        local balance, vehPaymentAmount = calculateFinance(vehiclePrice, downPayment, paymentAmount)
        if cash >= downPayment then
            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, balance, paymentamount, paymentsleft, financetime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                target.PlayerData.license,
                cid,
                vehicle,
                GetHashKey(vehicle),
                '{}',
                plate,
                Config.DefaultGarage,
                0,
                balance,
                vehPaymentAmount,
                paymentAmount,
                timer
            })
            TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', target.PlayerData.source, vehicle, plate)
            target.Functions.RemoveMoney('cash', downPayment, 'vehicle-bought-in-showroom')
            player.Functions.AddMoney('bank', commission, 'vehicle sale commission')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.earned_commission', { amount = comma_value(commission) }), 'success')
            exports['qb-banking']:AddMoney(player.PlayerData.job.name, vehiclePrice, 'Vehicle sale')
            TriggerClientEvent('QBCore:Notify', target.PlayerData.source, Lang:t('success.purchased'), 'success')
        elseif bank >= downPayment then
            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state, balance, paymentamount, paymentsleft, financetime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                target.PlayerData.license,
                cid,
                vehicle,
                GetHashKey(vehicle),
                '{}',
                plate,
                Config.DefaultGarage,
                0,
                balance,
                vehPaymentAmount,
                paymentAmount,
                timer
            })
            TriggerClientEvent('qb-vehicleshop:client:buyShowroomVehicle', target.PlayerData.source, vehicle, plate)
            target.Functions.RemoveMoney('bank', downPayment, 'vehicle-bought-in-showroom')
            player.Functions.AddMoney('bank', commission, 'vehicle sale commission')
            TriggerClientEvent('QBCore:Notify', src, Lang:t('success.earned_commission', { amount = comma_value(commission) }), 'success')
            exports['qb-banking']:AddMoney(player.PlayerData.job.name, vehiclePrice, 'Vehicle sale')
            TriggerClientEvent('QBCore:Notify', target.PlayerData.source, Lang:t('success.purchased'), 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notenoughmoney'), 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.playertoofar'), 'error')
    end
end)

-- Check if payment is due
RegisterNetEvent('qb-vehicleshop:server:checkFinance', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local query = 'SELECT * FROM player_vehicles WHERE citizenid = ? AND balance > 0 AND financetime < 1'
    local result = MySQL.query.await(query, { player.PlayerData.citizenid })
    if result[1] then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('general.paymentduein', { time = Config.PaymentWarning }))
        Wait(Config.PaymentWarning * 60000)
        local vehicles = MySQL.query.await(query, { player.PlayerData.citizenid })
        for _, v in pairs(vehicles) do
            local plate = v.plate
            MySQL.query('DELETE FROM player_vehicles WHERE plate = @plate', { ['@plate'] = plate })
            --MySQL.update('UPDATE player_vehicles SET citizenid = ? WHERE plate = ?', {'REPO-'..v.citizenid, plate}) -- Use this if you don't want them to be deleted
            TriggerClientEvent('QBCore:Notify', src, Lang:t('error.repossessed', { plate = plate }), 'error')
        end
    end
end)

-- Transfer vehicle to player in passenger seat
QBCore.Commands.Add('transfervehicle', Lang:t('general.command_transfervehicle'), { { name = 'ID', help = Lang:t('general.command_transfervehicle_help') }, { name = 'amount', help = Lang:t('general.command_transfervehicle_amount') } }, false, function(source, args)
    local src = source
    local buyerId = tonumber(args[1])
    local sellAmount = tonumber(args[2])
    if buyerId == 0 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.Invalid_ID'), 'error') end
    local ped = GetPlayerPed(src)
    local targetPed = GetPlayerPed(buyerId)
    if targetPed == 0 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.buyerinfo'), 'error') end
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notinveh'), 'error') end
    local plate = QBCore.Shared.Trim(GetVehicleNumberPlateText(vehicle))
    if not plate then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.vehinfo'), 'error') end
    local player = QBCore.Functions.GetPlayer(src)
    local target = QBCore.Functions.GetPlayer(buyerId)
    local row = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', { plate })
    if Config.PreventFinanceSelling then
        if row.balance > 0 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.financed'), 'error') end
    end
    if row.citizenid ~= player.PlayerData.citizenid then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.notown'), 'error') end
    if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > 5.0 then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.playertoofar'), 'error') end
    local targetcid = target.PlayerData.citizenid
    local targetlicense = QBCore.Functions.GetIdentifier(target.PlayerData.source, 'license')
    if not target then return TriggerClientEvent('QBCore:Notify', src, Lang:t('error.buyerinfo'), 'error') end
    if not sellAmount then
        MySQL.update('UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ?', { targetcid, targetlicense, plate })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.gifted'), 'success')
        TriggerClientEvent('vehiclekeys:client:SetOwner', buyerId, plate)
        TriggerClientEvent('QBCore:Notify', buyerId, Lang:t('success.received_gift'), 'success')
        return
    end
    if target.Functions.GetMoney('cash') > sellAmount then
        MySQL.update('UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ?', { targetcid, targetlicense, plate })
        player.Functions.AddMoney('cash', sellAmount, 'transferred vehicle')
        target.Functions.RemoveMoney('cash', sellAmount, 'transferred vehicle')
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.soldfor') .. comma_value(sellAmount), 'success')
        TriggerClientEvent('vehiclekeys:client:SetOwner', buyerId, plate)
        TriggerClientEvent('QBCore:Notify', buyerId, Lang:t('success.boughtfor') .. comma_value(sellAmount), 'success')
    elseif target.Functions.GetMoney('bank') > sellAmount then
        MySQL.update('UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ?', { targetcid, targetlicense, plate })
        player.Functions.AddMoney('bank', sellAmount, 'transferred vehicle')
        target.Functions.RemoveMoney('bank', sellAmount, 'transferred vehicle')
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.soldfor') .. comma_value(sellAmount), 'success')
        TriggerClientEvent('vehiclekeys:client:SetOwner', buyerId, plate)
        TriggerClientEvent('QBCore:Notify', buyerId, Lang:t('success.boughtfor') .. comma_value(sellAmount), 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.buyertoopoor'), 'error')
    end
end)
