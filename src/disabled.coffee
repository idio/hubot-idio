# Description:
#   List which alerts are currently disabled within SD
#
# Configuration:
#   HUBOT_SERVERDENSITY_TOKEN: required
#
# Commands:
#   hubot disabled
#
# Author:
#   Muz Ali

request = require 'request'

module.exports = (robot) ->

  robot.respond /disabled/i, (msg) ->

    if not process.env.HUBOT_SERVERDENSITY_TOKEN?
      msg.send "No ServerDensity token configured. Womp womp"
      return

    url = 'https://api.serverdensity.io/alerts/configs/?filter={%22enabled%22:false}&token=' + process.env.HUBOT_SERVERDENSITY_TOKEN

    request.get { uri: url, json: true }, (err, r, body) ->
      results = body

      if results.length < 1
        msg.send "No disabled alerts found"
        return

      msg.send "Disabled alerts:"
      
      for result in results
        name = ''

        if result['subjectType'] is 'service'
          s_url = "https://api.serverdensity.io/inventory/services/#{result['subjectId']}/?token=" + process.env.HUBOT_SERVERDENSITY_TOKEN
          request.get { uri: s_url, json: true }, (err, r, body) -> name = body['name']

        else if result['subjectType'] is 'deviceGroup'
          name = result['subjectId']

        msg.send "#{name} - #{result['fullField']} #{result['comparison']} #{result['value']}"
