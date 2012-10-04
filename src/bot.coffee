irc = require 'irc'
http = require 'http'
request = require 'request'
async = require 'async'

module.exports = class Bot

  constructor: (@server, @channels, @nick = 'ghbot')->
    @paths = {}
    @since = new Date()

    @irc = new irc.Client @server, @nick, { @channels }
    @irc.on 'message', @handleMessage

    setInterval @poll, 10000

  handleMessage: (from, to, message) =>
    message = message.split ' '
    command = message[0]

    @add message[1] if command.match /!add/
    @remove message[1] if command.match /!remove/
    @poll() if command.match /!check/


  add: (path) ->
    @paths[path] = true
    console.log @paths

  remove: (path) ->
    delete @paths[path]
    console.log @paths

  poll: =>
    sinceIso = @since.toISOString()
    @since = new Date()

    console.log 'polling since', sinceIso
    
    async.forEach Object.keys(@paths), (path, cb) ->
      path = path.split '/'
      owner = path[0]
      repo = path[1]
      
      request.get "https://api.github.com/repos/#{owner}/#{repo}/commits?since=#{sinceIso}", (e, r, body) =>
        console.log JSON.parse(body)
    , (e) ->
      console.log 'done', e