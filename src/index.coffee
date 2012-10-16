program = require 'commander'
Bot = require './bot'
settings = require '../settings'
user = settings.USER
pass = settings.PASS
server = settings.SERVER
channel = settings.CHANNEL

bot = new Bot server, channel, user, pass

