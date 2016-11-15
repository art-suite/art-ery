commander = require "commander"
.version (require './package.json').version
.option '-p, --port <number>',      "set the HTTP port"
.option '-r, --require <file>',     'require your pipelines with this'
.option '-w, --workers <number>',   'number of workers'
.option '-s, --static [path]',      'path to server static assets out of'
.parse process.argv

{log, ConfigRegistry} = require 'art-foundation'
Server  = require './Server'

if commander.require
  log "loading: #{commander.require }"
  require commander.require

# normally this is hangled by art-suite-app/Client, /Node or /Server
ConfigRegistry.configure()

server = new Server.Main
  verbose: true
  Art: Ery: verbose: true
  port: commander.port
  numWorkers: commander.workers || 1
  static: commander.static && root: commander.static
.start()
