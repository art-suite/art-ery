commander = require "commander"
.version (require './package.json').version
.option '-p, --port <number>',      "set the HTTP port"
.option '-r, --require <file>',     'require your pipelines with this'
.option '-w, --workers <number>',   'number of workers'
.option '-s, --static [path]',      'path to server static assets out of'
.parse process.argv

{log} = require 'art-foundation'
Server  = require './Server'

if commander.require
  log "loading: #{commander.require }"
  require commander.require

server = new Server.Main
  verbose: true
  port: commander.port
  numWorkers: commander.workers || 1
  static: commander.static && root: commander.static
.start()
