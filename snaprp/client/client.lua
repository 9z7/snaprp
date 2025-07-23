local showPhone = false
local inCamera = false
local camera

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
        showPhone = false
        SetNuiFocus(false, false)
        cb({ok = true})

        -- Create a custom camera
        camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamActive(camera, true)
        RenderScriptCams(true, false, 0, true, true)
        SetCamCoord(camera, GetEntityCoords(PlayerPedId()))
        SetCamRot(camera, GetEntityRotation(PlayerPedId()))

        CreateThread(function()
            while inCamera do
                Wait(0)
                -- You can add controls here to move the camera

                if IsControlJustPressed(0, 27) then -- Enter key to take photo
                    exports['screenshot-basic']:requestScreenshot(function(data)
                        TriggerServerEvent("snaprp:saveStory", data)
                    end, {
                        encoding = "jpg",
                        quality = 0.9
                    })
                    Wait(500) -- Wait for screenshot to be processed
                    inCamera = false
                end
            end
            -- Cleanup
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(camera, false)
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

RegisterCommand("testcam", function()
    if not inCamera then
        inCamera = true
        -- Create a custom camera
        camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamActive(camera, true)
        RenderScriptCams(true, false, 0, true, true)
        SetCamCoord(camera, GetEntityCoords(PlayerPedId()))
        SetCamRot(camera, GetEntityRotation(PlayerPedId()))

        CreateThread(function()
            while inCamera do
                Wait(0)
                -- You can add controls here to move the camera

                if IsControlJustPressed(0, 27) then -- Enter key to take photo
                    exports['screenshot-basic']:requestScreenshot(function(data)
                        -- Do nothing
                    end, {
                        encoding = "jpg",
                        quality = 0.9
                    })
                    Wait(500) -- Wait for screenshot to be processed
                    inCamera = false
                end
            end
            -- Cleanup
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(camera, false)
        end)
    end
end, false)
