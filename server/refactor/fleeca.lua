local config = require 'config.server'
local sharedConfig = require 'config.shared'
local robberyBusy = false
GlobalState.robberyBusy = false
local timeOut = false
local copsCalled

local function getClosestBank()
    local closestBankKey = 0
    local closestDistance = 30.0
    local playerCoords = GetEntityCoords(GetPlayerPed(source))

    for key, bank in pairs(sharedConfig.smallBanks) do
        local distance = #(playerCoords - bank.coords)
        if distance < closestDistance then
            closestDistance = distance
            closestBankKey = key
        end
    end

    return closestBankKey
end

---Changes the bank state
---@param bankId string | number
---@param state boolean
local function changeBankState(bankId, state)
    local bankName = type(bankId) == 'number' and 'bankrobbery' or bankId
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', bankName, state)
end

local function setBankTimeout(bankId)
    if GlobalState.robberyBusy or timeOut then return end

    timeOut = true
    CreateThread(function()
        SetTimeout(60000 * 30, function()
            for k in pairs(sharedConfig.smallBanks[bankId].lockers) do
                sharedConfig.smallBanks[bankId].lockers[k].isOpened = false
                sharedConfig.smallBanks[bankId].lockers[k].isBusy = false
            end

            TriggerClientEvent('qbx_bankrobbery:client:resetFleecaLockers', -1, bankId)
            timeOut = false
            GlobalState.robberyBusy = false
            changeBankState(bankId, false)
        end)
    end)
end

local function setBankState(bankId)
    if GlobalState.robberyBusy then return end

    if sharedConfig.smallBanks[bankId].isOpened or #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.smallBanks[bankId].coords) > 2.5 then
        return error(locale('error.event_trigger_wrong', { event = 'qbx_bankrobbery:server:setBankState', extraInfo = ' (smallbank '..bankId..') ', source = source }))
    end

    sharedConfig.smallBanks[bankId].isOpened = true
    setBankTimeout(bankId)

    TriggerClientEvent('qbx_bankrobbery:client:setBankState', -1, bankId)
    GlobalState.robberyBusy = true

    local bankName = type(bankId) == 'number' and 'bankrobbery' or bankId
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', bankName, true)
    if bankName ~= 'bankrobbery' then return end
    TriggerEvent('qb-banking:server:SetBankClosed', bankId, true)
    changeBankState(bankId, true)
end

RegisterNetEvent('qbx_bankrobbery:server:useElectronicKit', function()
    local closestBank = getClosestBank()

    if closestBank == 0 then return end

    if GlobalState.robberyBusy then 
        exports.qbx_core:Notify(source, locale('error.security_lock_active'), 'error', 5500)
        return
    end

    if CurrentCops < config.minFleecaPolice then 
        exports.qbx_core:Notify(source, (locale('error.minimum_police_required'):format(config.minFleecaPolice)), 'error') 
        return 
    end

    if sharedConfig.smallBanks[closestBank].isOpened then 
        exports.qbx_core:Notify(source, locale('error.bank_already_open'), 'error') 
        return
    end

    local hasItems = (exports.ox_inventory:Search(source, 'count', 'trojan_usb') > 0) and (exports.ox_inventory:Search(source, 'count', 'electronickit') > 0)
    if not hasItems then 
        exports.qbx_core:Notify(source, locale('error.missing_item'), 'error') 
        return
    end

    local success = lib.callback.await('qbx_bankrobbery:server:useElectronicKit', source)
    if not success then
        exports.qbx_core:Notify(source, locale('error.cancel_message'), 'error')
        return
    end

    setBankState(closestBank)

    exports.ox_inventory:RemoveItem(source, 'electronickit', 1)
    exports.ox_inventory:RemoveItem(source, 'trojan_usb', 1)

    if copsCalled or not sharedConfig.smallBanks[closestBank].alarm then return end
    --TriggerServerEvent('qbx_bankrobbery:server:callCops', 'small', closestBank, sharedConfig.smallBanks[closestBank].coords)
    copsCalled = true
    SetTimeout(60000 * config.outlawCooldown, function() 
        copsCalled = false 
    end)
end)