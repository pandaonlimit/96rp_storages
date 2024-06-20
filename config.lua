---------------------------------------------------------------------------------------------------------------------------------
--                                                  Confing
---------------------------------------------------------------------------------------------------------------------------------

Config = {}

Config.locations = {
    ["Storage"] = {
        neededJob = "taxi",
        storages = {
            ["Storage1"] = { 
                maxWeight = 4000000,
                maxSlots = 400,
                label = "Storage Nr.1", 
                position = vec4(969.72, 3438.44, 15.37, 86.1),
                size = vec3(2.0, 2.0, 2.0),
                interactDistance = 2
            },
        }
   }
}
Config.storageOptions = {
    {
        event = "96rp_storages:openStorage",
        label = "Open storage",
        inventoryName = "",
        locationName = "",
        job = false,
        owner = false
    },
    {
        event = "96rp_storages:changePassword",
        label = "Change passoword",
        inventoryName = "",
        locationName = "",
        job = true,
        owner = true
    },
    {
        event = "96rp_storages:addOwner",
        label = "Add renter",
        inventoryName = "",
        locationName = "",
        job = true,
        owner = false
    },
    {
        event = "96rp_storages:changeStatus",
        label = "Storage status",
        inventoryName = "",
        locationName = "",
        job = true,
        owner = false
    },
}