AddEventHandler('QBCore:Client:OnPlayerLoaded', function() 
    CreateStorages()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == 'ox_inventory'  or resourceName == GetCurrentResourceName() then
        CreateStorages()
    end
end)

function CreateStorages()
    for locationKey, locationValues in pairs(Config.locations) do 
        for storageKey, storageValues in pairs(locationValues.storages) do
            local storageName = locationKey .. storageKey
            print(storageName)
            exports.ox_target:addBoxZone({
                coords = storageValues.position,
                size = storageValues.size,
                rotation = storageValues.position.w,
                debug = true,
                drawSprite = true,
                options = GetOptions(storageName, locationValues.neededJob, locationValues.interactDistance, locationKey)
            })
        end
    end
end

function GetOptions(storageName, neededJob, interactDistance, locationName)
    local options = {}
    for _, storageOptions in pairs(Config.storageOptions)
    do
        table.insert(options, {
            label = storageOptions.label,
            distance = interactDistance,
            event = storageOptions.event,
            storageName = storageName,
            locationName = locationName,
            canInteract = function(entity, distance, coords, name, bone)
                if storageOptions.job and QBX.PlayerData.jobs[neededJob] then
                    return true
                end
                if storageOptions.owner and QBX.PlayerData.citizenid == GlobalState['96rp_storages'][storageName].owner.value then
                    return true
                end
                if not storageOptions.owner and not storageOptions.job and GlobalState['96rp_storages'][storageName].isActive.value == 1 then
                    return true
                end
                return false
            end
        })
    end
    return options
end

RegisterNetEvent('96rp_storages:openStorage', function(data)
    local neededJob = Config.locations[data.locationName].neededJob
    if QBX.PlayerData.jobs[neededJob] then
        exports.ox_inventory:openInventory('stash', data.storageName)
    else
        local input = lib.inputDialog('Open storage', {
            { type = "input", label = "Password", password = true, icon = 'lock' }
        })
        if input
        then
            TriggerServerEvent('96rp_storages:openStorage', data.storageName, data.locationName, input[1])
        end
    end
end)

RegisterNetEvent('96rp_storages:changePassword', function(data)
    local input = lib.inputDialog('Change password', {
        { type = "input", label = "New password", password = true, icon = 'lock' }
    })
    if input
    then 
        if GlobalState['96rp_storages'][data.storageName].owner.value == QBX.PlayerData.citizenid
        then
            lib.callback('96rp_storages:changePasswordCallback', false, function(success)
                if success
                then
                    lib.notify({
                        title = 'Storage',
                        description = 'Password changed',
                        type = 'success',
                        position = 'bottom',
                        duration = 4000
                    })
                else
                    lib.notify({
                        title = 'Storage',
                        description = 'Password change failed',
                        type = 'error',
                        position = 'bottom',
                        duration = 4000
                    })
                end
            end, data.storageName, data.locationName, input[1])
        end
    end
end)

RegisterNetEvent('96rp_storages:addOwner', function(data)
    local input = lib.inputDialog('Add/Change owner', { 'Owner id' })
    if input
    then
        lib.callback('96rp_storages:changeOwnerCallback', false, function(success)
            if success
                then
                    lib.notify({
                        title = 'Storage',
                        description = 'Owner added',
                        type = 'success',
                        position = 'bottom',
                        duration = 4000
                    })
                else
                    lib.notify({
                        title = 'Storage',
                        description = 'Owner add failed',
                        type = 'error',
                        position = 'bottom',
                        duration = 4000
                    })
                end
        end, data.storageName, data.locationName, tonumber(input[1]))
    end
end)

RegisterNetEvent('96rp_storages:changeStatus', function(data)
    local input = lib.inputDialog(data.label, {
        { type = "checkbox", label = "Aktivitäts-Status", checked = GlobalState['96rp_storages'][data.storageName].isActive.value }
    })
    if input
    then
        lib.callback('96rp_storages:changeActiveStatus', false, function(success)
            if success
            then
                lib.notify({
                    title = 'Storage',
                    description = 'Storage status changed',
                    type = 'success',
                    position = 'bottom',
                    duration = 4000
                })
            else
                lib.notify({
                    title = 'Storage',
                    description = 'Storage status change failed',
                    type = 'error',
                    position = 'bottom',
                    duration = 4000
                })
            end
        end, data.locationName, data.storageName, input[1])
    end
end)