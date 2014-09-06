# Description:
#   A way to ask hubot if you're an official SSE member
#
# Commands:
#   hubot is <dce> a member?
#   hubot am i a member?

Fuse = require "fuse.js"

module.exports = (robot) ->
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"
  
  _log = (level, message) ->
    if arguments.length is 1
      message = level
      level = 'debug'
    robot.logger[level] "[hubot-scoreboard#{ level }] #{ message }"

  robot.respond /is (.+) a member/i, (msg) ->
    name = msg.match[1]
    _log 'info', "Requesting scoreboard for #{ name }"
    searchMe msg, name, _log, (isMember) ->
      _log 'info', "Requested scoreboard, resolved membership for #{ name } to #{ isMember }"
      msg.send if isMember then "Yep, #{isMember}'s a member" else "Nope, #{ name } is not a member yet"
        
  robot.respond /am i a member/i, (msg) ->
    name = msg.message.user.name
    _log 'info', "Requesting scoreboard for #{ name }"
    searchMe msg, name, _log, (isMember) ->
      _log 'info', "Requested scoreboard, resolved membership for #{ name } to #{ isMember }"
      msg.send if isMember then "Yep, #{isMember}'s a member" else "Nope, #{ name } is not a member yet"

searchMe = (msg, dce, _log, cb) ->
  _log 'info', "Dispatching request for #{ dce }"
  found = false
  
  failed = 0
  failure = () ->
    failed++
    _log 'info', "Logged failure no. #{ failed }"
    if (failed is 2)
      cb(false)
  
  msg.http('https://sse.se.rit.edu')
    .path("scoreboard/api/members/#{ dce }")
    .get() (err, res, body) ->
      _log 'info', "Got members response for #{ dce }, resp no. #{ calls }."
      if ((!err) and (!found))
        resp = JSON.parse(body)
        if (resp.full_name)
          found = true;
          return cb(resp.full_name)
      failure()

  msg.http('https://sse.se.rit.edu')
    .path("scoreboard/api/high_scores")
    .get() (err, res, body) ->
      _log 'info', "Got high scores response. resp no. #{ calls }."
      if ((!err) and (!found))
        resp = JSON.parse(body)
        options = {
          keys: ['full_name'],
          id: 'full_name',
          threshold: 0.5 #Gotta be pretty close
        }
        f = new Fuse(resp, options)
        result = f.search(dce)
        _log 'info', "Fuzzy matched: #{ result }."
        if (result.length > 0)
          found = true;
          return cb(result[0])
      else
        if (!found)
          _log 'info', "High score response error: #{ err }"
      failure()