local storagesLoaded = false

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == 'ox_inventory'  or resourceName == GetCurrentResourceName() then
        CreateStorages()
    end
end)
AddEventHandler('onClientResourceStop', function (resourceName)
    for i = 1, i < #zones do
        exports.ox_target:removeZone(zones[i])
    end
end)

function CreateStorages()
    for locationKey, locationValues in pairs(Config.locations) do 
        local npcData = locationValues.automationSystem
        local npc = 0
        local isAutomationSystemActive = locationValues.automationSystem.active
        if isAutomationSystemActive then
            npc = Npc:new({
                name = "mynpc",
                data = lib.points.new(npcData.npc.coords, npcData.npc.radius, npcData.npc),
            })
            npc:show()
        end
        for storageKey, storageValues in pairs(locationValues.storages) do
            local storageName = locationKey .. storageKey
            local zoneid = exports.ox_target:addBoxZone({
                coords = storageValues.position,
                size = storageValues.size,
                rotation = storageValues.position.w,
                debug = true,
                drawSprite = true,
                options = GetOptions(storageKey, storageName, storageValues.label, locationValues.neededJob, locationValues.interactDistance, locationKey, Config.storageOptions)
            })
            if isAutomationSystemActive then
                exports.ox_target:addLocalEntity(npc.ped, GetOptions(storageKey, storageName, storageValues.label, locationValues.neededJob, locationValues.interactDistance, locationKey, Config.npcOptions))
            end
        end
    end
end

function GetOptions(storageKey, storageName, storageLabel, neededJob, interactDistance, locationName, options)
    local _options = {}
    for _, currentOptions in pairs(options)
    do
        table.insert(_options, {
            label = string.format(currentOptions.label, storageLabel),
            distance = interactDistance,
            event = currentOptions.event,
            storageKey = storageKey,
            storageName = storageName,
            locationName = locationName,
            canInteract = function(entity, distance, coords, name, bone)
                local storageActive = currentOptions.storageActive
                if currentOptions.playerHasJob and not QBX.PlayerData.jobs[neededJob] then
                    return false
                end
                if currentOptions.isPlayerOwner and QBX.PlayerData.citizenid ~= GlobalState['96rp_storages'][storageName].owner.value then
                    return false
                end
                if storageActive == "yes" and GlobalState['96rp_storages'][storageName].isActive.value == 0 then
                    return false
                end
                if storageActive == "no" and GlobalState['96rp_storages'][storageName].isActive.value == 1 then
                    return false
                end
                return true
            end
        })
    end
    return _options
end

RegisterNetEvent('96rp_storages:openStorageClient', function(data)
    local neededJob = Config.locations[data.locationName].neededJob
    if QBX.PlayerData.jobs[neededJob] then
        TriggerServerEvent('96rp_storages:openStorageJobServer', data.storageName, data.locationName)
    else
        local input = lib.inputDialog(Config.ui.openStorageInput, {
            { type = "input", label = Config.ui.openStorageLabel, password = true, icon = 'lock' }
        })
        if input
        then
            TriggerServerEvent('96rp_storages:openStorageServer', data.storageName, data.locationName, input[1])
        end
    end
end)

RegisterNetEvent('96rp_storages:changePassword', function(data)
    local input = lib.inputDialog(Config.ui.changePasswordInput, {
        { type = "input", label = Config.ui.changePasswordLabel, password = true, icon = 'lock' }
    })
    if input
    then 
        lib.callback('96rp_storages:changePasswordCallback', false, function(success)
            if success
            then
                lib.notify({
                    title = Config.ui.notificationsTitle,
                    description = Config.ui.changePasswordSuccess,
                    type = 'success',
                    position = Config.ui.notificationsPosition,
                    duration = Config.ui.notificationsDuration
                })
            else
                lib.notify({
                    title = Config.ui.notificationsTitle,
                    description = Config.ui.changePasswordFail,
                    type = 'error',
                    position = Config.ui.notificationsPosition,
                    duration = Config.ui.notificationsDuration
                })
            end
        end, data.storageName, data.locationName, input[1])
    end
end)

RegisterNetEvent('96rp_storages:addOwner', function(data)
    local input = lib.inputDialog(Config.ui.changeOwnerInput, { Config.ui.changeOwnerHelp })
    if input
    then
        lib.callback('96rp_storages:addOwnerCallback', false, function(success)
            if success
                then
                    lib.notify({
                        title = Config.ui.notificationsTitle,
                        description = Config.ui.changeOwnerSuccess,
                        type = 'success',
                        position = Config.ui.notificationsPosition,
                        duration = Config.ui.notificationsDuration
                    })
                else
                    lib.notify({
                        title = Config.ui.notificationsTitle,
                        description = Config.ui.changeOwnerFail,
                        type = 'error',
                        position = Config.ui.notificationsPosition,
                        duration = Config.ui.notificationsDuration
                    })
                end
        end, data.storageName, data.locationName, tonumber(input[1]))
    end
end)

RegisterNetEvent('96rp_storages:changeStatus', function(data)
    local input = lib.inputDialog(data.label, {
        { type = "checkbox", label = Config.ui.changeStatusLabel, checked = GlobalState['96rp_storages'][data.storageName].isActive.value }
    })
    if input
    then
        lib.callback('96rp_storages:changeStatusCallback', false, function(success)
            if success
            then
                lib.notify({
                    title = Config.ui.notificationsTitle,
                    description = Config.ui.changeStatusSuccess,
                    type = 'success',
                    position = Config.ui.notificationsPosition,
                    duration = Config.ui.notificationsDuration
                })
            else
                lib.notify({
                    title = Config.ui.notificationsTitle,
                    description = Config.ui.changeStatusFail,
                    type = 'error',
                    position = Config.ui.notificationsPosition,
                    duration = Config.ui.notificationsDuration
                })
            end
        end, data.locationName, data.storageName, input[1])
    end
end)

RegisterNetEvent('96rp_storages:payRent', function(data)
    local nextRentPayment = GlobalState['96rp_storages'][data.storageName].nextRentPayment.value / 60 / 60
    local dueDate =  lib.callback.await('96rp_storages:getDueDateCallback', false, data.storageName)
    local input = lib.inputDialog(Config.ui.payRentHeader, {
        {type = 'number', label = 'Number input', description = string.format(Config.ui.payRentContent, math.floor(nextRentPayment), dueDate), icon = 'hashtag', min = 0, max = 10}
    })

    if input
    then
        lib.callback('96rp_storages:payRentCallback', false, function(success)
            if success
            then
                lib.notify({
                    title = Config.ui.notificationsTitle,
                    description = Config.ui.payRentSuccess,
                    type = 'success',
                    position = Config.ui.notificationsPosition,
                    duration = Config.ui.notificationsDuration
                })
            else
                lib.notify({
                    title = Config.ui.notificationsTitle,
                    description = Config.ui.payRentFail,
                    type = 'error',
                    position = Config.ui.notificationsPosition,
                    duration = Config.ui.notificationsDuration
                })
            end
        end, data.locationName, data.storageName, input[1])
    end
end)

RegisterNetEvent('96rp_storages:startRentingStorage', function(data)
    local locationData = Config.locations[data.locationName]
    local storageData = locationData.storages[data.storageKey]
    local input = lib.inputDialog(Config.ui.buyOwnershipHeader, {
        {type = 'number', label = 'Number input', description = string.format(Config.ui.buyOwnershipContent, data.storageName, storageData.rent, 1), icon = 'hashtag'}
    })

    if input
    then
        lib.callback('96rp_storages:startRentingStorageCallback', false, function(success)
            if success
            then
                lib.notify({
                    title = Config.ui.notificationsTitle,
                    description = Config.ui.buyOwnershipSuccess,
                    type = 'success',
                    position = Config.ui.notificationsPosition,
                    duration = Config.ui.notificationsDuration
                })
            else
                lib.notify({
                    title = Config.ui.notificationsTitle,
                    description = Config.ui.buyOwnershipFail,
                    type = 'error',
                    position = Config.ui.notificationsPosition,
                    duration = Config.ui.notificationsDuration
                })
            end
        end, data.locationName, data.storageName, input[1])
    end
end)