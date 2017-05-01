{ConfigRegistry} = require 'art-config'
Server  = require './Server'
require "./test/tests/Art/Ery/ClientServer/Pipelines"

ConfigRegistry.configure
  artConfig:
    verbose: true
    Art: Ery: verbose: true

Server.start
  static: root: "./test/public/"
