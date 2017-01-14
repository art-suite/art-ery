{defineModule, log, Promise} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class AfterEventsFilter extends Filter
  @handlers: {}

  @on: (pipeline, requestType, action) ->
    ((@handlers[pipeline] ||= {})[requestType]||=[]).push action

  @registerPipelineListener: (pipeline, requestType) ->
    pipelineName = pipeline.getName()
    return if ((@_registeredPipelineHandlers ||= {})[pipelineName]||={})[requestType]
    @_registeredPipelineHandlers[pipelineName][requestType] = true
    @on pipelineName, requestType, (request) => pipeline.handleRequestAfterEvent request

  @after
    all: (response) ->
      {pipeline, type} = response
      pipelineName = pipeline.getName()

      actionPromises = for action in AfterEventsFilter.handlers[pipelineName]?[type] || []
        action response

      Promise.all actionPromises
      .then -> response
