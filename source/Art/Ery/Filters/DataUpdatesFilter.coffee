{each, formattedInspect, deepMerge, merge, defineModule, log, Validator, m, isFunction} = require 'art-foundation'
Filter = require '../Filter'

###
A) Populate rootRequest.dataUpdates
B) if Neptune.Art.Flux is defined, and this is the rootRequest/response
   Perform 'local updates'
###
defineModule module, class DataUpdatesFilter extends Filter

  # for subrequests, this will still be on the server
  # for rootRequest, this will actually run on the app-client - which is where we need to do the Flux updates
  @location: "both"

  @after all: (response) ->
    if response.isRootResponse && response.location != "server" && Neptune.Art.Flux
      {dataUpdates, dataDeletes} = response.props

      {models} = Neptune.Art.Flux
      for pipelineName, dataUpdatesByKey of dataUpdates when isFunction (model = models[pipelineName])?.dataUpdated
        each dataUpdatesByKey, (data, key) -> model.dataUpdated key, data

      for pipelineName, dataUpdatesByKey of dataDeletes when isFunction (model = models[pipelineName])?.dataDeleted
        each dataUpdatesByKey, (data, key) -> model.dataDeleted key, data

    if !response.isRootResponse
      {key, type} = response
      key ?
      field = switch type
        when "create", "update" then "dataUpdates"
        when "delete" then "dataDeletes"

      if key && field
        {data, pipelineName, rootRequest: {responseProps}} = response
        responseProps[field] = deepMerge responseProps[field],
          "#{pipelineName}": "#{key}": response.data

    response
