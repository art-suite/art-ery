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
    pipelineName = listeningPipeline.getPipelineName()
    throw new Error "listeningPipeline must implement handleRequestAfterEvent" unless isFunction listeningPipeline.handleRequestAfterEvent
    throw new Error "listeningToPipelineName must be a string" unless isString listeningToPipelineName
    # return if ((@_registeredPipelineHandlers[pipelineName]||={})[listeningToPipelineName]||={})[requestType]
    # @_registeredPipelineHandlers[pipelineName][listeningToPipelineName][requestType] = true
    @on listeningToPipelineName, requestType, listeningPipeline

  @after
    all: (response) ->
      {pipeline, type} = response
      pipelineName = pipeline.getName()

      actionPromises = for actionOrPipeline in AfterEventsFilter.handlers[pipelineName]?[type] || []
        if isFunction actionOrPipeline.handleRequestAfterEvent
          actionOrPipeline.handleRequestAfterEvent response
        else
          actionOrPipeline response

      Promise.all actionPromises
      .then -> response
