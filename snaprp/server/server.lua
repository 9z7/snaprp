-- Execute the SQL file to create the tables
local sqlFile = LoadResourceFile(GetCurrentResourceName(), "snaprp.sql")
if sqlFile then
    MySQL.Async.execute(sqlFile)
end

function getPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in ipairs(identifiers) do
        if string.match(identifier, "steam:") then
            return identifier
        end
    end
    return nil
end

RegisterServerEvent('snaprp:saveStory')
AddEventHandler('snaprp:saveStory', function(screenshotUrl)
    local source = source
    local identifier = getPlayerIdentifier(source)
    if identifier then
        local username = GetPlayerName(source)
        MySQL.Async.execute('INSERT INTO snaprp_stories (identifier, username, image_url) VALUES (@identifier, @username, @image_url)', {
            ['@identifier'] = identifier,
            ['@username'] = username,
            ['@image_url'] = screenshotUrl
        })

        -- Update streak
        MySQL.Async.fetch('SELECT streak, last_story_timestamp FROM snaprp_streaks WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(result)
            local today = os.time()
            if result and #result > 0 then
                local lastStory = os.time(result[1].last_story_timestamp)
                local diff = os.difftime(today, lastStory) / (60 * 60 * 24)

                if diff >= 1 and diff < 2 then
                    MySQL.Async.execute('UPDATE snaprp_streaks SET streak = streak + 1, last_story_timestamp = NOW() WHERE identifier = @identifier', {
                        ['@identifier'] = identifier
                    })
                elseif diff >= 2 then
                    MySQL.Async.execute('UPDATE snaprp_streaks SET streak = 1, last_story_timestamp = NOW() WHERE identifier = @identifier', {
                        ['@identifier'] = identifier
                    })
                end
            else
                MySQL.Async.execute('INSERT INTO snaprp_streaks (identifier, streak, last_story_timestamp) VALUES (@identifier, 1, NOW())', {
                    ['@identifier'] = identifier
                })
            end
        end)
    end
end)

RegisterServerEvent('snaprp:likeStory')
AddEventHandler('snaprp:likeStory', function(storyId)
    local source = source
    local identifier = getPlayerIdentifier(source)
    if identifier then
        MySQL.Async.fetch('SELECT id FROM snaprp_likes WHERE story_id = @story_id AND identifier = @identifier', {
            ['@story_id'] = storyId,
            ['@identifier'] = identifier
        }, function(result)
            if result and #result > 0 then
                MySQL.Async.execute('DELETE FROM snaprp_likes WHERE id = @id', {
                    ['@id'] = result[1].id
                })
            else
                MySQL.Async.execute('INSERT INTO snaprp_likes (story_id, identifier) VALUES (@story_id, @identifier)', {
                    ['@story_id'] = storyId,
                    ['@identifier'] = identifier
                })
            end
        end)
    end
end)

RegisterServerEvent('snaprp:commentStory')
AddEventHandler('snaprp:commentStory', function(storyId, comment)
    local source = source
    local identifier = getPlayerIdentifier(source)
    if identifier then
        local username = GetPlayerName(source)
        MySQL.Async.execute('INSERT INTO snaprp_comments (story_id, identifier, username, comment) VALUES (@story_id, @identifier, @username, @comment)', {
            ['@story_id'] = storyId,
            ['@identifier'] = identifier,
            ['@username'] = username,
            ['@comment'] = comment
        })
    end
end)

RegisterServerEvent('snaprp:getPlayerProfile')
AddEventHandler('snaprp:getPlayerProfile', function(targetIdentifier)
    local source = source
    MySQL.Async.fetch('SELECT * FROM snaprp_profiles WHERE identifier = @identifier', {
        ['@identifier'] = targetIdentifier
    }, function(result)
        if result and #result > 0 then
            TriggerClientEvent('snaprp:playerProfile', source, result[1])
        end
    end)
end)

RegisterServerEvent('snaprp:updatePlayerStatus')
AddEventHandler('snaprp:updatePlayerStatus', function(status)
    local source = source
    local identifier = getPlayerIdentifier(source)
    if identifier then
        MySQL.Async.execute('UPDATE snaprp_profiles SET status = @status WHERE identifier = @identifier', {
            ['@status'] = status,
            ['@identifier'] = identifier
        })
    end
end)

AddEventHandler('playerJoining', function()
    local source = source
    local identifier = getPlayerIdentifier(source)
    if identifier then
        MySQL.Async.execute('INSERT INTO snaprp_profiles (identifier, online) VALUES (@identifier, 1) ON DUPLICATE KEY UPDATE online = 1', {
            ['@identifier'] = identifier
        })
    end
end)

AddEventHandler("playerDropped", function(reason)
    local source = source
    local identifier = getPlayerIdentifier(source)
    if identifier then
        MySQL.Async.execute('UPDATE snaprp_profiles SET online = 0 WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        })
    end
end)

RegisterServerEvent('snaprp:getStories')
AddEventHandler('snaprp:getStories', function()
    local source = source
    MySQL.Async.fetchAll('SELECT * FROM snaprp_stories ORDER BY timestamp DESC', {}, function(stories)
        if stories and #stories > 0 then
            local storyData = {}
            for i=1, #stories do
                local story = stories[i]
                MySQL.Async.fetchScalar('SELECT COUNT(id) as likes FROM snaprp_likes WHERE story_id = @story_id', {
                    ['@story_id'] = story.id
                }, function(likes)
                    MySQL.Async.fetchAll('SELECT * FROM snaprp_comments WHERE story_id = @story_id', {
                        ['@story_id'] = story.id
                    }, function(comments)
                        table.insert(storyData, {
                            id = story.id,
                            identifier = story.identifier,
                            username = story.username,
                            image_url = story.image_url,
                            timestamp = story.timestamp,
                            likes = likes,
                            comments = comments
                        })
                        if #storyData == #stories then
                            TriggerClientEvent('snaprp:stories', source, storyData)
                        end
                    end)
                end)
            end
        else
            TriggerClientEvent('snaprp:stories', source, {})
        end
    end)
end)
