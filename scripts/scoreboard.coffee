# Description:
#   A way to ask hubot if you're an official SSE member
#
# Commands:
#   hubot is <dce> a member?

module.exports = (robot) ->
  _log = (level, message) ->
    if arguments.length is 1
      message = level
      level = 'debug'
    robot.logger[level] "[hubot-scoreboard#{ level }] #{ message }"
    
  robot.respond /is (.+) a member/i, (msg) ->
    name = msg.match[1]
    _log 'info', "Requesting scoreboard for #{ name }"
    searchMe msg, name, (isMember) ->
      _log 'info', "Requested scoreboard, resolved membership for #{ name } to #{ isMember }"
      msg.send isMember and "Yep, #{name}'s a member" or "Nope, #{ name } is not a member yet"

searchMe = (msg, dce, cb) ->
  msg.http('https://sse.se.rit.edu/scoreboard/members/'+dce)
    .get() (err, res, body) ->
      if (err or body.indexOf('Not a member')>-1 or body.indexOf('No Such Member')>-1)
        cb false
      cb true
