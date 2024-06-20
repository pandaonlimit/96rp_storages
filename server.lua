local playerMaxDistance = 5
AddEventHandler('onServerResourceStart', function(resourceName) --stashes
	if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName()
	then
		local storages = {}

		for locationKey,locationValues in pairs(Config.locations)
        do
			
			for storageKey, storageValues in pairs(locationValues.storages)
			do
				local storageName = locationKey .. storageKey
				local storage = GetStorageInfo(storageName)

				if storage == nil
				then
					MySQL.insert('INSERT INTO 96rp_storages VALUES(?, NULL, ?, NULL, 0)', { storageName, locationKey })
					storage = {isActive = 0}
				end

				storages[storageName] = storage
				exports.ox_inventory:RegisterStash(storageName, storageValues.label, storageValues.maxSlots, storageValues.maxWeight, nil, {[locationValues.neededJob] = 0})
			end
		end

		GlobalState['96rp_storages'] = storages
	end

	CreateThread(function()
		local storages = {}
		while true do
			print("--------------------------")
			print("update database check")
			local dbUpdated = false

			for storageKey, storageValues in pairs(GlobalState['96rp_storages']) do
				local changedValues = ""

				for key, values in pairs(storageValues) do
					if values.changed then
						print(string.format("	about to update %s -> %s in %s", key, values.value, storageKey))
						changedValues = changedValues .. string.format("%s = '%s', ", key, values.value)
						values.changed = false
					end
				end
				
				if #changedValues > 1 then
					local result = MySQL.update.await(string.format('UPDATE 96rp_storages SET %s where storage = ?', changedValues:sub(1, -3)), { storageKey })
					dbUpdated = true
					print(string.format("	update successful = %s", result))
				end

				storages[storageKey] = storageValues
			end

			if dbUpdated then
				GlobalState['96rp_storages'] = storages
				print("update finished")
			end
			print("--------------------------")
			Wait(10000)
		end
	end)
end)

RegisterNetEvent('96rp_storages:openStorage', function(storageName, locationName, password)
	local src = source
	local storageData = GetStorageData(locationName, storageName)

	if storageData then
		local playerCoords = GetEntityCoords(GetPlayerPed(src))
		local storagePosition = vec3(storageData.position.x, storageData.position.y, storageData.position.z)

		if #(playerCoords - storagePosition) <= playerMaxDistance and password == GlobalState['96rp_storages'][storageName].password.value then
			exports.ox_inventory:forceOpenInventory(src, 'stash', storageName)
		end
	end
end)

lib.callback.register('96rp_storages:changePasswordCallback', function(src, storageName, locationName, newPassword)
	local playerData = exports.qbx_core:GetPlayer(src).PlayerData.jobs
	local playerCoords = GetEntityCoords(GetPlayerPed(src))
	local location = Config.locations[locationName]
	local storageData = GetStorageData(locationName, storageName)
	
	if storageData then
		local storagePosition = vec3(storageData.position.x, storageData.position.y, storageData.position.z)

		if #(playerCoords - storagePosition) <= playerMaxDistance and (playerData.jobs[location.neededJob] or GlobalState['96rp_storages'][storageName].owner.value == playerData.citizenid) then
			GlobalState['96rp_storages'] = ChangeStorageValue(storageName, "password", newPassword)
			return (true)
		end
	end

	return (false)
end)

lib.callback.register('96rp_storages:changeOwnerCallback', function(src, storageName, locationName, newOwnerId)
	local playerJobs = exports.qbx_core:GetPlayer(src).PlayerData.jobs
	local playerCoords = GetEntityCoords(GetPlayerPed(src))
	local newOwner = exports.qbx_core:GetPlayer(newOwnerId)
	local location = Config.locations[locationName]
	local storageData = GetStorageData(locationName, storageName)

	if newOwner and storageData then
		local storagePosition = vec3(storageData.position.x, storageData.position.y, storageData.position.z)

		if playerJobs[location.neededJob] and #(playerCoords - storagePosition) <= playerMaxDistance then
			GlobalState['96rp_storages'] = ChangeStorageValue(storageName, "owner", newOwner.PlayerData.citizenid)
			return(true)
		end
	end
	
	return(false)
end)

lib.callback.register('96rp_storages:changeActiveStatus', function(src, locationName, storageName, status)
	local playerJobs = exports.qbx_core:GetPlayer(src).PlayerData.jobs
	local playerCoords = GetEntityCoords(GetPlayerPed(src))
	local location = Config.locations[locationName]
	local storageData = GetStorageData(locationName, storageName)
	if storageData then
		local storagePosition = vec3(storageData.position.x, storageData.position.y, storageData.position.z)
		if playerJobs[location.neededJob] and #(playerCoords - storagePosition) <= playerMaxDistance then
			if status then
				status = 1
			else
				status = 0
			end
			GlobalState['96rp_storages'] = ChangeStorageValue(storageName, "isActive", status)
			return (true)
		end
	end

	return (false)
end)

function GetStorageData(locationName, storageName)
	local location = Config.locations[locationName]

	for storageKey, storageValue in pairs(location.storages) do
		local currentStorageName = locationName .. storageKey

		if currentStorageName == storageName then
			return storageValue
		end
	end

	return nil
end

function GetStorageInfo(storageName)
	local storage = {}
	local result = MySQL.single.await('SELECT password, owner, isActive FROM 96rp_storages WHERE storage = @storage', { ['@storage'] = storageName })

	for key, value in pairs(result) do
		storage[key] = { changed = false, value = value}
	end

	return storage
end

function ChangeStorageValue(storageName, key, newValue)
	local currentStorageData = GlobalState['96rp_storages']

	currentStorageData[storageName][key] = {
		value = newValue,
		changed = true
	}

	return currentStorageData
end