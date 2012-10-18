irc = require 'irc'
connect = require 'connect'
http = require 'http'
request = require 'request'
c = require 'irc-colors'
_ = require 'underscore'

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

    port = process.env.NODE_PORT or 1337
    http.createServer(server).listen port, ->
      console.log "Running on port #{port}"

  shortUrl: (url, cb) ->
    request.post 'http://git.io', form:
      url: url
    , (e, r) =>
      cb r.headers.location
      
  handleRequest: (req, res) =>
    if !req.url.match /\/commit/ or req.method isnt 'POST'
      res.statusCode = 404
      return res.end 'Not found'

    payload = JSON.parse req.body.payload

    numCommits = payload.commits.length
    mainAuthor = payload.head_commit.committer.username or payload.head_commit.committer.name
    authors = (commit.committer.username for commit in payload.commits)
    otherAuthors = _.uniq(authors).length - 1
    repoPath = payload.repository.owner.name + '/' + payload.repository.name


    message = c.underline mainAuthor

    if otherAuthors
      message += " and #{otherAuthors} other"
      message += if otherAuthors > 1 then "s have" else " has"

    message += " made #{numCommits} change"
    message += if numCommits > 1 then "s " else " "

    @shortUrl payload.compare, (shorturl) =>
      message += "to #{c.bold(repoPath)} #{c.red(shorturl)} : "
      commit_messages = payload.head_commit.message.split "\n"
      commit_first_line = commit_messages[0]
      message += c.gray commit_first_line

      @irc.say @channels, message
      return res.end message

