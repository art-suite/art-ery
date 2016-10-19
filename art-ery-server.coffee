require './src/Art'
{select} = require 'art-foundation'
Server = require './src/Art/Ery/.Server'

{version} = require './package.json'

{defaults} = Server.Main

commander = require "commander"
.version version
.option '-p, --port <number>',     'set the HTTP port (default: #{defaults.port})'
.parse process.argv

Server.Main.start select commander, "port"