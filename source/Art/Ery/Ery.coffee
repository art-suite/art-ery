PipelineRegistry = require "./PipelineRegistry"
Filters = require './Filters'
{log, Promise} = require 'art-standard-lib'

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
    Filters._resetFilters()

  sendInitializeRequestToAllPipelines: ->
    promises = for k, pipeline of PipelineRegistry.pipelines
      if pipeline.class.getHandlers().initialize
        pipeline.initialize()

    Promise.all promises
]
