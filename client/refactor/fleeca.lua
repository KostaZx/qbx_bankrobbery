local config = require 'config.client'
local sharedConfig = require 'config.shared'
CurrentThermiteGate = 0
CurrentCops = 0
local closestBank = 0
local inElectronickitZone = false
local copsCalled = false
local refreshed = false
local currentLocker = 0

CreateThread(function()
    for i = 1, #sharedConfig.smallBanks do
        exports.ox_target:addBoxZone({
            coords = sharedConfig.smallBanks[i].coords,
            size = vec3(1, 1, 2),
            rotation = sharedConfig.smallBanks[i].coords.closed,
            debug = config.debugPoly,
            drawSprite = true,
            options = {
                {
                    label = 'Eletronic kit',
                    name = ('fleeca_%s_coords_electronickit'):format(i),
                    icon = 'fa-solid fa-vault',
                    distance = 1.5,
                    canInteract = function()
                    end,
                    onSelect = function()
                    end,
                },
            },
        })

        for k in pairs(sharedConfig.smallBanks[i].lockers) do
            exports.ox_target:addBoxZone({
                coords = sharedConfig.smallBanks[i].lockers[k].coords,
                size = vec3(1, 1, 2),
                rotation = sharedConfig.smallBanks[i].heading.closed,
                debug = config.debugPoly,
                drawSprite = true,
                options = {
                    {
                        label = locale('general.break_safe_open_option_target'),
                        name = ('fleeca_%s_coords_locker_%s'):format(i, k),
                        icon = 'fa-solid fa-vault',
                        distance = 1.5,
                        canInteract = function()
                            return closestBank ~= 0 and not isDrilling and sharedConfig.smallBanks[i].isOpened and not sharedConfig.smallBanks[i].lockers[k].isOpened and not sharedConfig.smallBanks[i].lockers[k].isBusy
                        end,
                        onSelect = function()
                            OpenLocker(closestBank, k)
                        end,
                    },
                },
            })
        end
    end
end)

--- This will open the bank door of any small bank
--- @param bankId number
--- @return nil
local function openFleecaDoor(bankId)
    local object = GetClosestObjectOfType(sharedConfig.smallBanks[bankId].coords.x, sharedConfig.smallBanks[bankId].coords.y, sharedConfig.smallBanks[bankId].coords.z, 5.0, sharedConfig.smallBanks[bankId].object, false, false, false)
    local entHeading = sharedConfig.smallBanks[bankId].heading.closed

    if object == 0 then return end

    CreateThread(function()
        while entHeading ~= sharedConfig.smallBanks[bankId].heading.open do
            SetEntityHeading(object, entHeading - 10)
            entHeading -= 0.5
            Wait(10)
        end
    end)
end

lib.callback.register('qbx_bankrobbery:client:useElectronicKit', function()
    if lib.progressBar({
        duration = 7500,
        label = locale('general.connecting_hacking_device'),
        canCancel = true,
        useWhileDead = false,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        },
        anim = {
            dict = 'anim@gangops@facility@servers@',
            clip = 'hotwire',
            flag = 1
        }
    }) then
        TriggerServerEvent('qbx_bankrobbery:server:removeElectronicKit')
        ---TriggerEvent('mhacking:show')
        --TriggerEvent('mhacking:start', math.random(6, 7), math.random(15, 30), onHackDone)
    else
        exports.qbx_core:Notify(locale('error.cancel_message'), 'error')
    end
end)

RegisterNetEvent('qbx_bankrobbery:client:resetFleecaLockers', function(bankId)
    sharedConfig.smallBanks[bankId].isOpened = false

    for k in pairs(sharedConfig.smallBanks[bankId].lockers) do
        sharedConfig.smallBanks[bankId].lockers[k].isOpened = false
        sharedConfig.smallBanks[bankId].lockers[k].isBusy = false
    end
end)

RegisterNetEvent('qbx_bankrobbery:client:setFleecaState', function(bankId)
    sharedConfig.smallBanks[bankId].isOpened = true
    openFleecaDoor(bankId)
end)