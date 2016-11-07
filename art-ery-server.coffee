{log, select} = require 'art-foundation'
Server  = require './Server'

{version} = require './package.json'

{defaults} = Server.Main

commander = require "commander"
.version version
.option '-p, --port <number>',     'set the HTTP port (default: #{defaults.port})'
.option '-r, --require <file>',    'require your pipelines with this'
.parse process.argv

commander.port ||= process.env.PORT

if commander.require
  log "loading: #{commander.require }"
  require commander.require

Server.Main.start select commander, "port"