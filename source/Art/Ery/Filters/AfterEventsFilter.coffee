{defineModule, log, Promise, isFunction, isString} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class AfterEventsFilter extends Filter
  @handlers: {}
  @_registeredPipelineHandlers: {}

  # for testing
  @_reset: => AfterEventsFilter.handlers = {}; @_registeredPipelineHandlers = {}

  @on: (pipeline, requestType, action) ->
    ((@handlers[pipeline] ||= {})[requestType]||=[]).push action

  @registerPipelineListener: (listeningPipeline, listeningToPipelineName, requestType) ->
    pipelineName = listeningPipeline.getPipelineName()
    throw new Error "listeningPipeline must implement handleRequestAfterEvent" unless isFunction listeningPipeline.handleRequestAfterEvent
    throw new Error "listeningToPipelineName must be a string" unless isString listeningToPipelineName
    return if ((@_registeredPipelineHandlers[pipelineName]||={})[listeningToPipelineName]||={})[requestType]
    @_registeredPipelineHandlers[pipelineName][listeningToPipelineName][requestType] = true
    @on listeningToPipelineName, requestType, (request) =>
      listeningPipeline.handleRequestAfterEvent request

  @after
    all: (response) ->
      {pipeline, type} = response
      pipelineName = pipeline.getName()

      actionPromises = for action in AfterEventsFilter.handlers[pipelineName]?[type] || []
        action response

      Promise.all actionPromises
      .then -> response
