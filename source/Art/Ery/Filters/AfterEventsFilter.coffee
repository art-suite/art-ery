{defineModule, log, Promise, isFunction, isString, pushIfNotPresent} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class AfterEventsFilter extends Filter
  @handlers: {}
  @_registeredPipelineHandlers: {}

  # for testing
  @_reset: => AfterEventsFilter.handlers = {}; @_registeredPipelineHandlers = {}

  @on: (pipelineName, requestType, actionOrPipeline) ->
    pushIfNotPresent ((@handlers[pipelineName] ||= {})[requestType]||=[]), actionOrPipeline

  @registerPipelineListener: (listeningPipeline, listeningToPipelineName, requestType) ->
    throw new Error "listeningPipeline must implement handleRequestAfterEvent" unless isFunction listeningPipeline.handleRequestAfterEvent
    throw new Error "listeningToPipelineName must be a string" unless isString listeningToPipelineName
    @on listeningToPipelineName, requestType, listeningPipeline

  @sendEvents: (response, pipelineName, requestType) ->
    actionPromises = for actionOrPipeline in AfterEventsFilter.handlers[pipelineName]?[requestType] || []
      if isFunction actionOrPipeline.handleRequestAfterEvent
        actionOrPipeline.handleRequestAfterEvent response
      else
        actionOrPipeline response

    Promise.all actionPromises
    .then -> response

  @after
    all: (response) ->
      {pipeline, type} = response
      pipelineName = pipeline.getName()

      AfterEventsFilter.sendEvents response, pipelineName, type

