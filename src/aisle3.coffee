# Description:
#   Aisle 3
#
#   A hubot script that removes references to terminated AWS servers
#   from Chef and Server Density
#
# Configuration:
#   HUBOT_AWS_PUBLIC: required
#   HUBOT_AWS_REGION: required
#   HUBOT_AWS_SECRET: required
#   HUBOT_CHEF_HOST: required
#   HUBOT_CHEF_KEY: required
#   HUBOT_CHEF_USER: required
#   HUBOT_SERVERDENSITY_TOKEN: required
#
# Commands:
#   hubot aisle3 clean - Clean up terminated server references
#   hubot aisle3 status - Summary of terminated server references
#
# Notes:
#   This command uses AWS as the aribiter of a server's status,
#   regardless of what Chef or SD might report.
#
# Author:
#   Mal Graty

read = require('fs').readFileSync

aws = require 'aws-sdk'
chef = require 'chef'

config = {}
Object.keys(process.env).forEach (k) ->
  key = k.replace(/^HUBOT_/, '')
  config[key] = process.env[k] unless key is k

module.exports = (robot) ->

  # clients

  ec2 = new aws.EC2
    accessKeyId: config.AWS_ACCESS
    secretAccessKey: config.AWS_SECRET
    region: config.AWS_REGION

  hat = chef.createClient \
    config.CHEF_USER,
    read(config.CHEF_KEY),
    config.CHEF_HOST

  sda = robot
    .http('https://api.serverdensity.io')
    .header('accept', 'application/json')
    .query token: config.SERVERDENSITY_TOKEN

  # requests

  servers = ->
    new Promise (res, rej) ->
      ec2.describeInstanceStatus (err, data) ->
        return rej err if err
        out = data.InstanceStatuses
          .filter((i) -> i.InstanceState.Name isnt 'terminated')
          .map (i) -> i.InstanceId
        res out

  clients = ->
    new Promise (res, rej) ->
      query = 'admin:false AND validator:false AND NOT (name:dashboard)'
      format = name: ['name']
      hat.post "/search/client?q=#{query}", format, (err, data) ->
        return rej err if err
        res data.body.rows.map (c) -> c.data.name

  nodes = ->
    new Promise (res, rej) ->
      query = 'name:*'
      format = id: ['ec2', 'instance_id'], name: ['name']
      hat.post "/search/node?q=#{query}", format, (err, data) ->
        return rej err if err
        res data.body.rows.reduce (o, n) ->
          if n.data.id
            o[n.data.id] = n.data.name
          else
            o.orphans.push n.data.name
          o
        , orphans: []

  devices = ->
    new Promise (res, rej) ->
      sda.path('/inventory/devices').get() (err, head, body) ->
        return rej err if err
        try
          data = JSON.parse(body)
          res data.reduce (o, d) ->
            name = d.name + if d.deleted then ' (hidden)' else ''
            o[d.providerId] = id: d._id, name: name; o
          , {}
        catch err
          rej err

  # utilities

  finalise = (res, id) -> (err, data) ->
    if err
      console.error err.stack ? err
      id += ' [failed]'
    res id

  error = (e) -> e.stack ? 'Error: ' + e
  spread = (fn) -> -> fn.apply null, arguments[0]
  values = (o) -> Object.keys(o).map (k) -> o[k]

  # pipe

  command = (fn) ->
    Promise.all([servers(), clients(), nodes(), devices()])
      .then(organise)
      .then(fn)
      .then(summary)

  organise = spread (servers, clients, nodes, devices) ->
    safe = {}

    nodes.orphans.forEach (o) ->
      safe[o] = 0
    delete nodes.orphans

    servers.forEach (s) ->
      safe[nodes[s]] = 0
      delete nodes[s]
      delete devices[s]

    clients = clients.filter (c) -> c not of safe

    Promise.resolve [clients, values(nodes), values(devices)]

  summary = spread (prefix, clients, nodes, devices) ->
    message = []

    format = (description, items) -> if items.length
      description = description.replace /^(\w+)s/, '$1' if items.length is 1
      message.push "#{prefix} #{items.length} unmatched #{description}:"
      message = message.concat items.map (i) -> "\u2003#{i}"

    format 'clients in Chef', clients
    format 'nodes in Chef', nodes
    format 'devices in Server Density', devices

    unless message.length
      message.push 'Looks clear, can\'t find anything to clean up'

    Promise.resolve message.join '\n'

  # commands

  clean = spread (clients, nodes, devices) ->
    clients = Promise.all clients.map (c) -> new Promise (res) ->
      hat.delete "/clients/#{c}", finalise res, c

    nodes = Promise.all nodes.map (n) -> new Promise (res) ->
      hat.delete "/nodes/#{n}", finalise res, n

    devices = Promise.all devices.map (d) -> new Promise (res) ->
      sda.path("/inventory/devices/#{d.id}").del() finalise res, d.name

    message = Promise.resolve 'Cleaned up'
    Promise.all([message, clients, nodes, devices])

  list = spread (clients, nodes, devices) ->
    devices = devices.map (d) -> d.name
    Promise.resolve ['Found', clients, nodes, devices]

  # hooks

  robot.respond /aisle3 clean/i, (msg) ->
    command(clean)
      .then((out) -> msg.send out)
      .catch (e) -> msg.send error e

  robot.respond /aisle3 (?:list|stat(?:e|us))/i, (msg) ->
    command(list)
      .then((out) -> msg.send out)
      .catch (e) -> msg.send error e
