irc = require 'irc'
connect = require 'connect'
http = require 'http'
request = require 'request'
c = require 'irc-colors'

module.exports = class Bot

  constructor: (@server, @channels, @user, @pass, @nick = 'ghbot')->
    @paths = {}
    #cheap way to do auth now, will OAuth
    @header =
        'auth': "#{@user}:#{@pass}"

    @irc = new irc.Client @server, @nick, { @channels }

    server = connect()
    server.use connect.favicon()
    server.use connect.logger 'dev'
    server.use connect.bodyParser()
    server.use @handleRequest
    http.createServer(server).listen 1337, ->
      console.log 'Running on port 1337'
      
  handleRequest: (req, res) =>
    if !req.url.match /\/commit/ or req.method isnt 'POST'
      res.statusCode = 404
      return res.end 'Not found'

    payload = JSON.parse req.body.payload
    console.log payload

    return res.end 'woot'
    
    if commits?.length
      @paths[path] = new Date()

      commits.forEach (commit) =>
        commit.url = "http://github.com/#{owner}/#{repo}/commit/#{commit.sha}"
        request.post "http://git.io", form:
            url:commit.url
        , (e,r, body) =>
            committer = if commit.committer then commit.committer.login else commit.commit.committer.name
            commit_pieces = commit.commit.message.split '\n'
            for item in commit_pieces
                console.log "begin:"+item+'\n'
            shortlog = commit_pieces[0]
            commit.url = r.headers.location
            commit.message = "#{c.underline(committer)} just made a change to #{c.bold(path)} #{c.red(commit.url)} : #{c.gray(shortlog)}"
            @irc.say @channels, commit.message


