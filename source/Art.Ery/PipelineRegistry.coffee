{defineModule, each, compactFlatten, log, BaseObject, decapitalize, isClass, inspect} = require "art-foundation"

defineModule module, class PipelineRegistry extends BaseObject
  @pipelines: pipelines = {}

  # returns the singleton
  @register: (PipelineClass) ->
    {singleton, _aliases} = PipelineClass

    _aliases && for alias in _aliases
      pipelines[alias] = singleton

    pipelines[singleton.name] = singleton

  # used for testing
  @_reset: (testFunction = -> true) ->
    each (Object.keys pipelines), (key) ->
      if testFunction pipelines[key]
        delete pipelines[key]

