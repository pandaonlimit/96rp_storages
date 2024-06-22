local playerMaxDistance = 5
local currentTime = os.time()
AddEventHandler('onServerResourceStart', function(resourceName) --stashes
	if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName() then
		local storages = {}

		for locationKey,locationValues in pairs(Config.locations) do
			for storageKey, storageValues in pairs(locationValues.storages) do
				local storageName = locationKey .. storageKey
				local storage = GetStorageInfo(storageName)
				
				if next(storage) == nil
				then
					MySQL.insert('INSERT INTO 96rp_storages VALUES(?, NULL, ?, "no owner", 0, 0)', { storageName, locationKey })
					storage = { isActive = { changed = false, value = 0 }, owner = { changed = false, value = "no owner" }, nextRentPayment = { changed = false, value = 0 } }
				end

				storages[storageName] = storage
				exports.ox_inventory:RegisterStash(storageName, storageValues.label, storageValues.maxSlots, storageValues.maxWeight, "LA094J44")
			end
		end

		GlobalState['96rp_storages'] = storages
	end

	CreateThread(function()
		local waitTime = 60000
		while true do
			for locationKey, locationValues in pairs(Config.locations) do
				for storageName, storageValues in pairs(GlobalState['96rp_storages']) do
					local isStorageActive = GlobalState['96rp_storages'][storageName].isActive.value
					local storageOwner = GlobalState['96rp_storages'][storageName].owner.value
					
					if locationValues.automationSystem.active and isStorageActive == 1 and storageOwner ~= "no owner" then
						local nextRentPayment = tonumber(GlobalState['96rp_storages'][storageName].nextRentPayment.value)
						
						if nextRentPayment <= 0 then
							GlobalState['96rp_storages'] = ChangeStorageValues(storageName, {
								owner = "no owner",
								isActive = 0
							})
						else
							GlobalState['96rp_storages'] = ChangeStorageValue(storageName, "nextRentPayment", nextRentPayment - waitTime / 1000)		
						end
					end
				end
			end
			Wait(waitTime)
		end
	end)

	CreateThread(function()
		local waitTime = 600000
		while true do
			print("--------------------------")
			print("update database check")
			UpdateDatabase()
			print("--------------------------")
			Wait(waitTime)
		end
	end)
end)

RegisterCommand("saveStorages", function(source, args, rawCommand)
	UpdateDatabase()
end, true) 

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
	UpdateDatabase()
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
	UpdateDatabase()
end)

RegisterNetEvent('96rp_storages:openStorageServer', function(storageName, locationName, password)
	local src = source
	local storageData = GetStorageData(locationName, storageName)

	if storageData then
		local playerCoords = GetEntityCoords(GetPlayerPed(src))
		local storagePosition = vec3(storageData.position.x, storageData.position.y, storageData.position.z)
		if #(playerCoords - storagePosition) <= playerMaxDistance and password == GlobalState['96rp_storages'][storageName].password.value then
			print("open")
			exports.ox_inventory:forceOpenInventory(src, 'stash', { id = storageName, job = Config.locations[locationName].neededJob })
		end
	end
end)

RegisterNetEvent('96rp_storages:openStorageJobServer', function(storageName, locationName)
	local src = source
	local storageData = GetStorageData(locationName, storageName)
	local neededJob = Config.locations[locationName].neededJob
	local playerJobs = exports.qbx_core:GetPlayer(src).PlayerData.jobs

	if storageData then
		local playerCoords = GetEntityCoords(GetPlayerPed(src))
		local storagePosition = vec3(storageData.position.x, storageData.position.y, storageData.position.z)

		if #(playerCoords - storagePosition) <= playerMaxDistance and playerJobs[neededJob] then
			exports.ox_inventory:forceOpenInventory(src, 'stash', storageName)
		end
	end
end)

lib.callback.register('96rp_storages:changePasswordCallback', function(src, storageName, locationName, newPassword)
	local playerData = exports.qbx_core:GetPlayer(src).PlayerData
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

lib.callback.register('96rp_storages:addOwnerCallback', function(src, storageName, locationName, newOwnerId)
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

lib.callback.register('96rp_storages:changeStatusCallback', function(src, locationName, storageName, status)
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

lib.callback.register('96rp_storages:payRentCallback', function(src, locationName, storageName, payment)
	local playerData = exports.qbx_core:GetPlayer(src).PlayerData
	local playerCoords = GetEntityCoords(GetPlayerPed(src))
	local storageData = GetStorageData(locationName, storageName)
	local location = Config.locations[locationName]
	local payValue = payment * location.automationSystem.rentTimeMultiplicator
	print(payValue)
	if storageData then
		local storagePosition = vec3(storageData.position.x, storageData.position.y, storageData.position.z)

		if #(playerCoords - storagePosition) <= playerMaxDistance and GlobalState['96rp_storages'][storageName].owner.value == playerData.citizenid then
			local success = exports.ox_inventory:RemoveItem(src, 'cash', storageData.rent * payment)
			local nextRentPayment = GlobalState['96rp_storages'][storageName].nextRentPayment.value + payValue
			GlobalState['96rp_storages'] = ChangeStorageValue(storageName, "nextRentPayment", nextRentPayment)

			return (success)
		end
	end

	return (false)
end)

lib.callback.register('96rp_storages:getDueDateCallback', function(source, storageName)
	local dueDate = currentTime + GlobalState['96rp_storages'][storageName].nextRentPayment.value
    return os.date("%c", dueDate)
end)

lib.callback.register('96rp_storages:startRentingStorageCallback', function(src, locationName, storageName, payment)
	local playerCitizenid = exports.qbx_core:GetPlayer(src).PlayerData.citizenid
	local playerCoords = GetEntityCoords(GetPlayerPed(src))
	local storageData = GetStorageData(locationName, storageName)
	local location = Config.locations[locationName]
	local payValue = payment * location.automationSystem.rentTimeMultiplicator
	print(payValue)
	if storageData then
		local storagePosition = vec3(storageData.position.x, storageData.position.y, storageData.position.z)
		
		if #(playerCoords - storagePosition) <= playerMaxDistance and GlobalState['96rp_storages'][storageName].owner.value == "no owner" then
			local success = exports.ox_inventory:RemoveItem(src, 'cash', storageData.rent * payment)
			local nextRentPayment = GlobalState['96rp_storages'][storageName].nextRentPayment.value + payValue
			GlobalState['96rp_storages'] = ChangeStorageValues(storageName, {
				nextRentPayment = nextRentPayment,
				owner = playerCitizenid,
				isActive = 1
			})
			
			return (success)
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
	local result = MySQL.single.await('SELECT password, owner, isActive, nextRentPayment FROM 96rp_storages WHERE storage = @storage', { ['@storage'] = storageName })
	
	if result then
		for key, value in pairs(result) do
			storage[key] = { changed = false, value = value }
		end
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

function ChangeStorageValues(storageName, newValues)
	local currentStorageData = GlobalState['96rp_storages']

	for key, value in pairs(newValues)
	do
		currentStorageData[storageName][key] = {
			value = value,
			changed = true
		}
	end

	return currentStorageData
end

function UpdateDatabase()
	local storages = {}
	local dbUpdated = false
	currentTime = os.time()
	
	for storageName, storageValues in pairs(GlobalState['96rp_storages']) do
		local changedValues = ""

		for key, values in pairs(storageValues) do
			if values.changed then
				print(string.format("	about to update %s -> %s in %s", key, values.value, storageName))
				changedValues = changedValues .. string.format("%s = '%s', ", key, values.value)
				values.changed = false
			end
		end
		
		if #changedValues > 1 then
			local result = MySQL.update.await(string.format('UPDATE 96rp_storages SET %s where storage = ?', changedValues:sub(1, -3)), { storageName })
			dbUpdated = true
			print(string.format("	update successful = %s", result))
		end

		storages[storageName] = storageValues
	end

	if dbUpdated then
		GlobalState['96rp_storages'] = storages
		print("update finished")
	end
end