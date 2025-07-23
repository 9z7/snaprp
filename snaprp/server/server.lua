local ESX = exports["es_extended"]:getSharedObject()

-- Execute the SQL file to create the tables
local sqlFile = LoadResourceFile(GetCurrentResourceName(), "snaprp.sql")
if sqlFile then
    exports.oxmysql:execute(sqlFile)
end

RegisterServerEvent('snaprp:saveStory')
AddEventHandler('snaprp:saveStory', function(screenshotUrl)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local identifier = xPlayer.getIdentifier()
        local username = xPlayer.getName()

        -- Save the story
        exports.oxmysql:execute('INSERT INTO snaprp_stories (identifier, username, image_url) VALUES (?, ?, ?)', {
            identifier,
            username,
            screenshotUrl
        })

        -- Update streak
        exports.oxmysql:fetch('SELECT streak, last_story_timestamp FROM snaprp_streaks WHERE identifier = ?', { identifier }, function(result)
            local today = os.time()
            if result and #result > 0 then
                local lastStory = os.time(result[1].last_story_timestamp)
                local diff = os.difftime(today, lastStory) / (60 * 60 * 24) -- Difference in days

                if diff >= 1 and diff < 2 then
                    -- Continue streak
                    exports.oxmysql:execute('UPDATE snaprp_streaks SET streak = streak + 1, last_story_timestamp = NOW() WHERE identifier = ?', { identifier })
                elseif diff >= 2 then
                    -- Reset streak
                    exports.oxmysql:execute('UPDATE snaprp_streaks SET streak = 1, last_story_timestamp = NOW() WHERE identifier = ?', { identifier })
                end
            else
                -- First story, start streak
                exports.oxmysql:execute('INSERT INTO snaprp_streaks (identifier, streak, last_story_timestamp) VALUES (?, 1, NOW())', { identifier })
            end
        end)
    end
end)

RegisterServerEvent('snaprp:likeStory')
AddEventHandler('snaprp:likeStory', function(storyId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local identifier = xPlayer.getIdentifier()
        -- Check if the player has already liked the story
        exports.oxmysql:fetch('SELECT id FROM snaprp_likes WHERE story_id = ? AND identifier = ?', { storyId, identifier }, function(result)
            if result and #result > 0 then
                -- Unlike the story
                exports.oxmysql:execute('DELETE FROM snaprp_likes WHERE id = ?', { result[1].id })
            else
                -- Like the story
                exports.oxmysql:execute('INSERT INTO snaprp_likes (story_id, identifier) VALUES (?, ?)', { storyId, identifier })
            end
        end)
    end
end)

RegisterServerEvent('snaprp:commentStory')
AddEventHandler('snaprp:commentStory', function(storyId, comment)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local identifier = xPlayer.getIdentifier()
        local username = xPlayer.getName()
        exports.oxmysql:execute('INSERT INTO snaprp_comments (story_id, identifier, username, comment) VALUES (?, ?, ?, ?)', {
            storyId,
            identifier,
            username,
            comment
        })
    end
end)

-- Get player profile
RegisterServerEvent('snaprp:getPlayerProfile')
AddEventHandler('snaprp:getPlayerProfile', function(targetIdentifier)
    local sourcePlayer = ESX.GetPlayerFromId(source)
    exports.oxmysql:fetch('SELECT * FROM snaprp_profiles WHERE identifier = ?', { targetIdentifier }, function(result)
        if result and #result > 0 then
            sourcePlayer.triggerEvent('snaprp:playerProfile', result[1])
        end
    end)
end)

-- Update player status
RegisterServerEvent('snaprp:updatePlayerStatus')
AddEventHandler('snaprp:updatePlayerStatus', function(status)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local identifier = xPlayer.getIdentifier()
        exports.oxmysql:execute('UPDATE snaprp_profiles SET status = ? WHERE identifier = ?', { status, identifier })
    end
end)

-- Player online status
AddEventHandler('esx:onPlayerJoining', function(source, name, lastseen)
    local identifier = ESX.GetPlayerFromId(source).getIdentifier()
    exports.oxmysql:execute('INSERT INTO snaprp_profiles (identifier, online) VALUES (?, 1) ON DUPLICATE KEY UPDATE online = 1', { identifier })
end)

AddEventHandler('esx:onPlayerDropped', function(source, reason)
    local identifier = ESX.GetPlayerFromId(source).getIdentifier()
    exports.oxmysql:execute('UPDATE snaprp_profiles SET online = 0 WHERE identifier = ?', { identifier })
end)

-- Get all stories
RegisterServerEvent('snaprp:getStories')
AddEventHandler('snaprp:getStories', function()
    local sourcePlayer = ESX.GetPlayerFromId(source)
    exports.oxmysql:fetch('SELECT * FROM snaprp_stories ORDER BY timestamp DESC', {}, function(stories)
        if stories and #stories > 0 then
            local storyData = {}
            for i=1, #stories do
                local story = stories[i]
                exports.oxmysql:fetch('SELECT COUNT(id) as likes FROM snaprp_likes WHERE story_id = ?', { story.id }, function(likes)
                    exports.oxmysql:fetch('SELECT * FROM snaprp_comments WHERE story_id = ?', { story.id }, function(comments)
                        table.insert(storyData, {
                            id = story.id,
                            identifier = story.identifier,
                            username = story.username,
                            image_url = story.image_url,
                            timestamp = story.timestamp,
                            likes = likes[1].likes,
                            comments = comments
                        })
                        if #storyData == #stories then
                            sourcePlayer.triggerEvent('snaprp:stories', storyData)
                        end
                    end)
                end)
            end
        else
            sourcePlayer.triggerEvent('snaprp:stories', {})
        end
    end)
end)
