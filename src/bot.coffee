irc = require 'irc'
http = require 'http'
request = require 'request'
async = require 'async'
c = require 'irc-colors'
db = require('monk')('localhost/bot')
repos = db.get "repos"

module.exports = class Bot

  constructor: (@server, @channels, @nick = 'ghbot')->
    @paths = {}

    @irc = new irc.Client @server, @nick, { @channels }
    @irc.on 'message', @handleMessage

    setInterval @poll, 10000

    repos.find({},{stream:true}).each (repo)->
      owner = repo.owner
      r = repo.repo
      @add("#{owner}/#{r}")
      
  handleMessage: (from, to, message) =>
    message = message.split ' '
    command = message[0]

    @add message[1] if command.match /!add/
    @remove message[1] if command.match /!remove/
    @poll() if command.match /!check/


  add: (path) ->
    return if @paths[path]
    @paths[path] = new Date()
    pathSplit = path.split '/'
    owner = pathSplit[0]
    repo = pathSplit[1]
    repos.insert {owner,repo}

  remove: (path) ->
    delete @paths[path]
    pathSplit = path.split '/'
    owner = pathSplit[0]
    repo = pathSplit[1]
    repos.remove {owner,repo}

  poll: =>
    async.forEach Object.keys(@paths), (path, cb) =>
      pathSplit = path.split '/'
      owner = pathSplit[0]
      repo = pathSplit[1]
      since = @paths[path].toISOString()

      #console.log 'polling', path, 'since', since
      
      request.get "https://api.github.com/repos/#{owner}/#{repo}/commits?since=#{since}", (e, r, body) =>
        return if e or !body
        commits = JSON.parse(body)

        if commits?.length
          @paths[path] = new Date()

          commits.forEach (commit) =>
            commit.url = "http://github.com/#{owner}/#{repo}/commit/#{commit.sha}"
            request.post "http://git.io", form:
                url:commit.url
            , (e,r, body) =>
                commit.url = r.headers.location
                commit.message = "#{c.cyan(owner)} just made a change to #{c.bold.cyan(repo)} #{c.red(commit.url)}: \"#{c.gray(commit.commit.message)}\""
                @irc.say @channels, commit.message

    , (e) ->
      console.log 'done', e
