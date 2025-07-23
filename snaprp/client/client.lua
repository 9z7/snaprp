local showPhone = false
local inCamera = false

RegisterCommand("phone", function()
    if not inCamera then
        showPhone = not showPhone
        SetNuiFocus(showPhone, showPhone)
        SendNUIMessage({type = "openPhone"})
    end
end, false)

RegisterNUICallback("close", function(data, cb)
    showPhone = false
    SetNuiFocus(false, false)
    cb({ok = true})
end)

RegisterNUICallback("openCamera", function(data, cb)
    if not inCamera then
        inCamera = true
        CreateMobilePhone(1)
        CellCamActivate(true, true)
        showPhone = false
        SetNuiFocus(false, false)
        cb({ok = true})

        CreateThread(function()
            while CellCamIsActive() do
                Wait(0)
                if IsControlJustPressed(0, 27) then -- Enter key to take photo
                    exports['screenshot-basic']:requestScreenshot(function(data)
                        TriggerServerEvent("snaprp:saveStory", data)
                    end, {
                        encoding = "jpg",
                        quality = 0.9
                    })
                    Wait(500) -- Wait for screenshot to be processed
                    CellCamActivate(false, false)
                    DestroyMobilePhone()
                    inCamera = false
                end
            end
        end)
    end
end)

RegisterNetEvent('snaprp:stories')
AddEventHandler('snaprp:stories', function(stories)
    SendNUIMessage({
        type = "stories",
        stories = stories
    })
end)

RegisterNetEvent('snaprp:playerProfile')
AddEventHandler('snaprp:playerProfile', function(profile)
    SendNUIMessage({
        type = "playerProfile",
        profile = profile
    })
end)
