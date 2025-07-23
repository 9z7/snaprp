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
                local x, y, z = table.unpack(GetCamCoord(camera))
                local rotX, rotY, rotZ = table.unpack(GetCamRot(camera, 2))

                -- Move controls
                if IsControlPressed(0, 32) then -- W
                    local newX = x + 0.1 * (math.cos(math.rad(rotZ + 90)))
                    local newY = y + 0.1 * (math.sin(math.rad(rotZ + 90)))
                    SetCamCoord(camera, newX, newY, z)
                end
                if IsControlPressed(0, 33) then -- S
                    local newX = x - 0.1 * (math.cos(math.rad(rotZ + 90)))
                    local newY = y - 0.1 * (math.sin(math.rad(rotZ + 90)))
                    SetCamCoord(camera, newX, newY, z)
                end
                if IsControlPressed(0, 34) then -- A
                    local newX = x - 0.1 * (math.cos(math.rad(rotZ)))
                    local newY = y - 0.1 * (math.sin(math.rad(rotZ)))
                    SetCamCoord(camera, newX, newY, z)
                end
                if IsControlPressed(0, 35) then -- D
                    local newX = x + 0.1 * (math.cos(math.rad(rotZ)))
                    local newY = y + 0.1 * (math.sin(math.rad(rotZ)))
                    SetCamCoord(camera, newX, newY, z)
                end

                -- Rotation controls
                local mouseX = GetControlNormal(0, 239) -- MOUSE X
                local mouseY = GetControlNormal(0, 240) -- MOUSE Y
                SetCamRot(camera, rotX - mouseY * 5.0, 0.0, rotZ - mouseX * 5.0, 2)

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
