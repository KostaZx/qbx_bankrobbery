local config = require 'config.server'
local sharedConfig = require 'config.shared'
local robberyBusy = false
local timeOut = false


RegisterNetEvent('qbx_bankrobbery:server:setBankState', function(bankId)
    if robberyBusy then return end
    if bankId == 'paleto' then
        if sharedConfig.bigBanks.paleto.isOpened or #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.bigBanks.paleto.coords) > 2.5 then
            return error(locale('error.event_trigger_wrong', {event = 'qbx_bankrobbery:server:setBankState', extraInfo = ' (paleto) ', source = source}))
        end
        sharedConfig.bigBanks.paleto.isOpened = true
        TriggerEvent('qbx_bankrobbery:server:setTimeout')
    elseif bankId == 'pacific' then
        if sharedConfig.bigBanks.pacific.isOpened or #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.bigBanks.pacific.coords[2]) > 2.5 then
            return error(locale('error.event_trigger_wrong', {event = 'qbx_bankrobbery:server:setBankState', extraInfo = ' (pacific) ', source = source}))
        end
        sharedConfig.bigBanks.pacific.isOpened = true
        TriggerEvent('qbx_bankrobbery:server:setTimeout')
    else
        if sharedConfig.smallBanks[bankId].isOpened or #(GetEntityCoords(GetPlayerPed(source)) - sharedConfig.smallBanks[bankId].coords) > 2.5 then
            return error(locale('error.event_trigger_wrong', {event = 'qbx_bankrobbery:server:setBankState', extraInfo = ' (smallbank '..bankId..') ', source = source}))
        end
        sharedConfig.smallBanks[bankId].isOpened = true
        TriggerEvent('qbx_bankrobbery:server:SetSmallBankTimeout', bankId)
    end
    TriggerClientEvent('qbx_bankrobbery:client:setBankState', -1, bankId)
    robberyBusy = true

    local bankName = type(bankId) == 'number' and 'bankrobbery' or bankId
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', bankName, true)
    if bankName ~= 'bankrobbery' then return end
    TriggerEvent('qb-banking:server:SetBankClosed', bankId, true)
    changeBankState(bankId, true)
end)