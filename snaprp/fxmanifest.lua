fx_version 'cerulean'
game 'gta5'

author 'Jules'
description 'SnapRP - A Snapchat-like script for FiveM'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/style.css',
    'web/js/script.js'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

dependencies {
    'es_extended',
    'screenshot-basic',
    'oxmysql'
}
