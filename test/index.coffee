ArtMocha = require "art-foundation/src/art/dev_tools/test/mocha"
require 'art-flux'
require '../'
require '../Filters'
require '../Flux'

ArtMocha.run ({assert})->
  self.testAssetRoot = "/test/assets"
  require './tests'
