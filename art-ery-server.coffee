require './src/Art'
Server = require './src/Art/Ery/.Server'

{version} = require './package.json'

{defaults} = Server.Main

commander = require "commander"
.version version
.option '-p, --port',     'set the HTTP port (default: #{defaults.port})'
.parse process.argv

Server.Main.start commander