PipelineRegistry = require "./PipelineRegistry"
Filters = require './Filters'

module.exports = [
  Filters
  pipelines: PipelineRegistry.pipelines
  session: (require './Session').singleton
  package: _package = require "art-ery/package.json"
  version: _package.version
  config: require('./Config').config

  # for testing
  _reset: ->
    PipelineRegistry._reset()
    Filters._reset()
]
