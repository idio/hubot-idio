# Description:
#   Squirrel
#
#   A hubot script that handles idio's day to day shipping operations
#
# Configuration:
#   HUBOT_IDIO_GIT_REMOTE_HOST: optional
#   HUBOT_IDIO_GIT_REMOTE_PREFIX: optional
#   HUBOT_IDIO_GIT_RR_CACHE: optional
#   HUBOT_IDIO_GIT_SSH_KEY: optional
#   HUBOT_IDIO_GIT_USER_EMAIL: required
#   HUBOT_IDIO_GIT_USER_NAME: required
#
# Commands:
#   hubot spin <repo> [type] - Spin a new minor or major release candidate
#   hubot ship <repo> [branches...] - Ship current release candidate or patch
#
# Notes:
#   The defaults are to spin minor versions and ship the most current
#   release candidate. By specifying more than one branch it is possible
#   to ship a patch containing multiple fixes.
#   A few flags are supported:
#     - Dry-Run: Performs all operations but does not push the changes
#     - Force: Ships with a force merge, can be helpful with path conflicts
#   A special pseudo repo "platform" exists to facilitate the necessary
#   lock-step shipping of a set of interdependant repos.
#
# Author:
#   Mal Graty

exec = require('child_process').execFile
resolve = require('path').resolve
semver = require 'semver'

config = {}
Object.keys(process.env).forEach (k) ->
  key = k.replace(/^HUBOT_IDIO_/, '')
  config[key] = process.env[k] unless key is k

module.exports = (robot) ->

  bin = resolve __dirname, '..', 'node_modules', '.bin'
  script = resolve __dirname, '..', 'bin', 'squirrel'

  email = robot.name.replace(/\W+/, '+').replace(/^\W+|\W+$/, '').toLowerCase()
  env = env:
    GIT_AUTHOR_EMAIL: config.GIT_USER_EMAIL ? "#{email}@hubot"
    GIT_AUTHOR_NAME: config.GIT_USER_NAME ? robot.name
    GIT_REMOTE_HOST: config.GIT_REMOTE_HOST ? ''
    GIT_REMOTE_PREFIX: config.GIT_REMOTE_PREFIX ? ''
    GIT_RR_CACHE: config.GIT_RR_CACHE ? ''
    GIT_SSH_KEY: config.GIT_SSH_KEY ? ''
    PATH: bin + ':' + process.env.PATH
  env.env.GIT_COMMITTER_EMAIL = env.env.GIT_AUTHOR_EMAIL
  env.env.GIT_COMMITTER_NAME = env.env.GIT_AUTHOR_NAME

  flags = d: 'dry-run', f: 'force'
  noflags = RegExp "[^#{Object.keys(flags).join('')}]"

  squirrel = (args...) ->
    args = args.filter (a) -> a
    new Promise (res, rej) ->
      exec script, args, env, (err, stdout, stderr) ->
        rej new Error stderr.replace(/^\w+:/, '').trim(), '' if err
        res stdout.trim()

  class Repo

    constructor: (@name) ->

    bump: (bump) ->
      if bump not in ['major', 'minor', 'patch']
        return Promise.reject new Error 'Invalid version granularity'
      @version().then (v) ->
        return Promise.resolve semver.inc v, bump

    release: ->
      squirrel 'release', @name

    spin: (opts, bump='minor') ->
      @bump(bump).then (v) =>
        squirrel 'spin', opts, @name, v

    ship: (opts, branches...) ->
      version = if branches.length then @bump 'patch' else @release()
      version.then (v) =>
        squirrel 'ship', opts, @name, v, branches...

    version: ->
      squirrel 'version', @name


  class Group

    process = (stack, fn) ->
      stack = stack.reverse()
      next = (results=[]) ->
        frame = stack.pop()
        promise = if Array.isArray frame then Promise.all frame.map fn else fn frame
        promise.then (res) ->
          results.push res
          if stack.length then next results else Promise.resolve results
      next()

    constructor: (@name, schema...) ->
      @schema = process schema, (r) -> Promise.resolve new Repo r

    proxy: (method, args) ->
      @schema.then((s) -> process s, (r) -> r[method] args...)
        .then (o) =>
          out = o.reduce ((s, f) -> s.concat(f)), []
          Promise.resolve o.shift().replace /^[\S]+/, @name

    spin: -> @proxy 'spin', arguments
    ship: -> @proxy 'ship', arguments


  respond = (msg) ->
    opts = msg.match[2] ? ''
    opts = opts.replace /[\-\s]+/g, ''
    if opts
      if noflags.test opts
        return msg.send 'Invalid flag; only -d and -f are supported'
      else
        opts = '-' + opts

    options = []
    for flag, desc of flags
      options.push desc if ~opts.indexOf flag
    options = if options.length then ' (' + options.join(', ') + ')' else ''

    method = msg.match[1]
    args = msg.match[3].split(/\s+/g).filter (v) -> v
    name = args.shift()

    repo = switch name
      when 'platform', 'it'
        new Group 'platform', 'cake', ['api', 'backend', 'manager' ]
      else
        new Repo name

    switch method
      when 'spin' then msg.send "Spinning #{name} ...#{options}"
      when 'ship' then msg.send "Shipping #{name} ...#{options}"

    repo[method](opts, args...)
      .then((o) -> msg.send o)
      .catch (e) -> msg.send e.message

  robot.respond /(ship|spin)((?:\s+-\w+)+)?\s+(\w.*)/i, respond
