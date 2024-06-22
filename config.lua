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
                interactDistance = 2,
                rent = 100,
            },
            ["Storage2"] = { 
                maxWeight = 4000000,
                maxSlots = 400,
                label = "Storage Nr.2", 
                position = vec4(969.67, 3443.83, 15.17, 93.47),
                size = vec3(2.0, 2.0, 2.0),
                interactDistance = 2,
                rent = 100,
            },
        },
        automationSystem = {
            active = true,
            rentTimeMultiplicator = 24 * 60 * 60,
            npc = {
                coords = vec3(969.75, 3439.99, 15.31),
                heading = 89.71,
                model = `cs_floyd`,
                clothing = {
                    component = {
                    },
                    prop = {
                    }
                },
                radius = 3,
                animation = false
            }
        }
   },
   ["Storage2"] = {
    neededJob = "taxi",
    storages = {
        ["Storage1"] = { 
            maxWeight = 4000000,
            maxSlots = 400,
            label = "Storage Nr.1", 
            position = vec4(969.76, 3432.36, 15.6, 78.67),
            size = vec3(2.0, 2.0, 2.0),
            interactDistance = 2,
            rent = 1,
        },
    },
    automationSystem = {
        rentTimeMultiplicator = 24 * 60 * 60,
        active = false,
        npc = {
            coords = vec3(969.75, 3439.99, 15.31),
            heading = 89.71,
            model = `cs_floyd`,
            clothing = {
                component = {
                },
                prop = {
                }
            },
            radius = 3,
            animation = false
        }
    }
}
}
Config.ui = {
    notificationsTitle = 'Storage',
    notificationsPosition = 'top',
    notificationsDuration = 4000,

    openStorageInput = 'Open storage',
    openStorageLabel = 'Password',

    changePasswordInput = 'Change password',
    changePasswordLabel = 'New password',
    changePasswordSuccess = 'Password changed',
    changePasswordFail = 'Password change failed',

    changeOwnerInput = 'Add/Change owner',
    changeOwnerSuccess = 'Owner added',
    changeOwnerHelp = 'Owner id',
    changeOwnerFail = 'Owner add failed',

    changeStatusLabel = 'Change storagte status',
    changeStatusSuccess = 'Storage status changed',
    changeStatusFail = 'Storage status change failed',

    payRentHeader = 'Reeeeeeeeeeent',
    payRentContent = 'Time until you lose ownership in %s hours | date: %s',
    payRentSuccess = 'Rent paid!',
    payRentFail = 'Rent payment failed',

    buyOwnershipHeader = 'Reeeeeeeeeeent',
    buyOwnershipContent = 'Buy %s ownership (%s dollars for %s days)',
    buyOwnershipSuccess = 'The ownership is yours!',
    buyOwnershipFail = 'Ownership transfer failed',

}

Config.storageOptions = {
    {
        event = "96rp_storages:openStorageClient",
        label = "Open storage",
        playerHasJob = false,
        isPlayerOwner = false,
        storageActive = "yes",
    },
    {
        event = "96rp_storages:changePassword",
        label = "Change password",
        playerHasJob = true,
        isPlayerOwner = false,
        storageActive = "yes",
    },
    {
        event = "96rp_storages:changePassword",
        label = "Change password",
        playerHasJob = false,
        isPlayerOwner = true,
        storageActive = "yes",
    },
    {
        event = "96rp_storages:addOwner",
        label = "Add renter",
        playerHasJob = true,
        isPlayerOwner = false,
        storageActive = "doesnt matter",
    },
    {
        event = "96rp_storages:changeStatus",
        label = "Storage status",
        playerHasJob = true,
        isPlayerOwner = false,
        storageActive = "doesnt matter",
    },
}

Config.npcOptions = {
    {
        event = "96rp_storages:payRent",
        label = "Pay rent for %s",
        playerHasJob = false,
        isPlayerOwner = true,
        storageActive = "yes",
    },
    {
        event = "96rp_storages:startRentingStorage",
        label = "Buy ownership for %s",
        playerHasJob = false,
        isPlayerOwner = false,
        storageActive = "no",
    },
}