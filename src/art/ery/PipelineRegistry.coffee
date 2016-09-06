{defineModule, log, BaseObject, decapitalize, isClass, inspect} = require "art-foundation"

defineModule module, class PipelineRegistry extends BaseObject
  @pipelines: pipelines = {}

  # returns the singleton
  @register: (PipelineClass) ->
    {singleton} = PipelineClass
    pipelines[singleton.name] = singleton

  # used for testing
  @_reset: -> delete pipelines[k] for k in Object.keys pipelines

