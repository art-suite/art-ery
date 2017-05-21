require 'art-flux/Core'
require '../'
{ArtEryFluxModel} = require '../Flux'

require "art-foundation/testing"
.init
  defineTests: ->
    tests = require './tests'
    ArtEryFluxModel.defineModelsForAllPipelines()
    tests
