# Description:
#   middleware
#
#   Middleware hooks to manipulate how jeff decides to respond, if at all
#
#   Author:
#     Muz Ali

WHITELISTED_ROOMS = [
  'GFX51NVJB', # Dev Chat
  'GFVAY3L1W', # Geeky
  'GFVAY3Q9E'  # Releasing
]

module.exports = (robot) ->
  robot.receiveMiddleware (context, next, done) ->
    if context.response.message.room not in WHITELISTED_ROOMS
      # For direct messages, and commands not in a whitelisted room bail out.
      done() 
    else
      next(done)
